defmodule PingPongMeasurer.Ping do
  use GenServer
  require Logger

  alias PingPongMeasurer.Data
  alias PingPongMeasurer.Data.Measurement

  defmodule State do
    defstruct process_index: 1, pong_process_pid: nil, data_directory_path: nil, measurements: []
  end

  def start_link(process_index) when is_integer(process_index) do
    process_name = process_name(process_index)
    initial_state = %State{process_index: process_index}

    {:ok, pid} = on_start = GenServer.start_link(__MODULE__, initial_state, name: process_name)
    :global.register_name(process_name, pid)

    on_start
  end

  def init(%State{process_index: index} = state) do
    Process.flag(:trap_exit, true)

    pong_prorcess_name = Module.concat(Elixir.PingPongMeasurer.Pong, "#{index}")
    pong_process_pid = :global.whereis_name(pong_prorcess_name)
    data_directory_path = Application.get_env(:ping_pong_measurer, :data_directory_path)

    with true <- is_pid(pong_process_pid),
         true <- not is_nil(data_directory_path),
         true <- File.dir?(data_directory_path) or :ok == File.mkdir_p!(data_directory_path) do
      {:ok,
       %State{
         state
         | pong_process_pid: pong_process_pid,
           data_directory_path: data_directory_path
       }}
    end
  end

  def terminate(
        reason,
        %State{
          measurements: measurements,
          data_directory_path: data_directory_path,
          process_index: process_index
        } = _state
      ) do
    Logger.debug("#{reason}")
    file_name = Data.file_name(DateTime.now!("Asia/Tokyo"), process_index)
    file_path = Path.join(data_directory_path, file_name)
    Data.save(file_path, measurements)
  end

  def cast_ping(process_index \\ 1, payload \\ "") do
    GenServer.cast(process_name(process_index), {:ping, payload})
  end

  def handle_cast(
        {:ping, payload},
        %State{pong_process_pid: pong_process_pid, measurements: measurements} = state
      ) do
    measurement = %Measurement{send_time: System.monotonic_time(:microsecond)}

    :ok = GenServer.cast(pong_process_pid, {:ping, self(), payload})

    {:noreply, %State{state | measurements: [measurement | measurements]}}
  end

  def handle_cast({:pong, _payload}, %State{measurements: [h | t]} = state) do
    measurement = %Measurement{h | recv_time: System.monotonic_time(:microsecond)}

    Logger.debug("#{(measurement.recv_time - measurement.send_time) / 1000} ms")

    {:noreply, %State{state | measurements: [measurement | t]}}
  end

  defp process_name(process_index) when is_integer(process_index) do
    Module.concat(__MODULE__, "#{process_index}")
  end
end

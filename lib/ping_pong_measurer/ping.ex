defmodule PingPongMeasurer.Ping do
  use GenServer
  require Logger

  alias PingPongMeasurer.Data
  alias PingPongMeasurer.Data.Measurement

  @ping_times 100
  @gen_server_call_time_out 15_000

  defmodule State do
    defstruct process_index: 0, pong_process_pid: nil, data_directory_path: nil, measurements: []
  end

  defmodule Measurement do
    defstruct measurement_time: nil, send_time: nil, recv_time: nil

    @type t() :: %__MODULE__{
            measurement_time: DateTime.t(),
            send_time: integer(),
            recv_time: integer()
          }
  end

  def start_link({data_directory_path, process_index})
      when is_binary(data_directory_path) and is_integer(process_index) do
    process_name = process_name(process_index)

    {:ok, pid} =
      on_start =
      GenServer.start_link(__MODULE__, {data_directory_path, process_index}, name: process_name)

    :global.register_name(process_name, pid)

    on_start
  end

  def init({data_directory_path, process_index}) do
    Process.flag(:trap_exit, true)

    pong_prorcess_name = Module.concat(Elixir.PingPongMeasurer.Pong, "#{process_index}")
    pong_process_pid = :global.whereis_name(pong_prorcess_name)

    cond do
      is_pid(pong_process_pid) == false ->
        Logger.error("cannot find pong process")
        {:stop, :normal}

      File.dir?(data_directory_path) == false ->
        Logger.error("#{data_directory_path} is not directory or doesn't exist")
        {:stop, :normal}

      true ->
        {:ok,
         %State{
           process_index: process_index,
           pong_process_pid: pong_process_pid,
           data_directory_path: data_directory_path
         }}
    end
  end

  def terminate(
        _reason,
        %State{
          measurements: measurements,
          data_directory_path: data_directory_path,
          process_index: process_index
        } = _state
      ) do
    # Logger.debug("#{inspect(reason)}")
    # ex. if process_index == 99, do: "0099.csv"
    file_name = "#{String.pad_leading("#{process_index}", 4, "0")}.csv"
    file_path = Path.join(data_directory_path, file_name)
    Data.save(file_path, [header() | body(measurements)])
  end

  def cast_ping(process_index \\ 0, payload \\ "") do
    GenServer.cast(process_name(process_index), {:ping, payload})
  end

  def call_ping(process_index \\ 0, payload \\ "") do
    GenServer.call(process_name(process_index), {:ping, payload}, @gen_server_call_time_out)
  end

  def handle_cast(
        {:ping, payload},
        %State{pong_process_pid: pong_process_pid, measurements: measurements} = state
      ) do
    measurement = %Measurement{
      measurement_time: DateTime.utc_now(),
      send_time: System.monotonic_time(:microsecond)
    }

    :ok = GenServer.cast(pong_process_pid, {:ping, self(), payload})

    {:noreply, %State{state | measurements: [measurement | measurements]}}
  end

  def handle_cast({:pong, _payload}, %State{measurements: [h | t]} = state) do
    measurement = %Measurement{h | recv_time: System.monotonic_time(:microsecond)}

    {:noreply, %State{state | measurements: [measurement | t]}}
  end

  def handle_call(
        {:ping, payload},
        _from,
        %State{
          process_index: process_index,
          pong_process_pid: pong_process_pid,
          measurements: measurements
        } = state
      ) do
    measurement = %Measurement{
      measurement_time: DateTime.utc_now(),
      send_time: System.monotonic_time(:microsecond)
    }

    for _ <- 1..@ping_times do
      {:pong, ^payload} =
        GenServer.call(pong_process_pid, {:ping, self(), payload}, @gen_server_call_time_out)
    end

    measurement = %Measurement{measurement | recv_time: System.monotonic_time(:microsecond)}
    measurements = [measurement | measurements]

    if process_index == 0 do
      Logger.debug(
        "measurements #{inspect(Enum.count(measurements))}: took time[ms] #{took_time_ms(measurement)}"
      )
    end

    {:reply, :ok, %State{state | measurements: measurements}}
  end

  defp process_name(process_index) when is_integer(process_index) do
    Module.concat(__MODULE__, "#{process_index}")
  end

  defp header() do
    [
      "measurement_time(utc)",
      "send time[microsecond]",
      "recv time[microsecond]",
      "took time[ms]"
    ]
  end

  @spec body([Measurement.t()]) :: list()
  defp body(measurements) when is_list(measurements) do
    Enum.reduce(measurements, [], fn %Measurement{} = measurement, rows ->
      row = [
        measurement.measurement_time,
        measurement.send_time,
        measurement.recv_time,
        took_time_ms(measurement)
      ]

      [row | rows]
    end)
  end

  defp took_time_ms(%Measurement{} = measurement) do
    (measurement.recv_time - measurement.send_time) / 1000
  end
end

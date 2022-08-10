defmodule PingPongMeasurer.Ping do
  use GenServer
  require Logger

  defmodule State do
    defstruct process_index: 1, pong_process_pid: nil, measurements: []
  end

  defmodule Measurement do
    defstruct send_time: nil, recv_time: nil
  end

  def start_link(process_index) when is_integer(process_index) do
    process_name = process_name(process_index)
    initial_state = %State{process_index: process_index}

    {:ok, pid} = on_start = GenServer.start_link(__MODULE__, initial_state, name: process_name)
    :global.register_name(process_name, pid)

    on_start
  end

  def init(%State{process_index: index} = state) do
    pong_prorcess_name = Module.concat(Elixir.PingPongMeasurer.Pong, "#{index}")
    pong_process_pid = :global.whereis_name(pong_prorcess_name)

    if is_pid(pong_process_pid) do
      {:ok, %State{state | pong_process_pid: pong_process_pid}}
    else
      reason = "can not find pong process"
      Logger.error(reason)
      {:stop, reason}
    end
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

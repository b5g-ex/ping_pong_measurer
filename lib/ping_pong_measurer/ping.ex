defmodule PingPongMeasurer.Ping do
  use GenServer
  require Logger

  defmodule State do
    defstruct pong_pid: nil, measurements: []
  end

  defmodule Measurement do
    defstruct send_time: nil, recv_time: nil
  end

  def start_link(_state) do
    {:ok, pid} = on_start = GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
    :global.register_name(__MODULE__, pid)
    on_start
  end

  def init(state) do
    pong_pid = :global.whereis_name(Elixir.PingPongMeasurer.Pong)

    if is_pid(pong_pid) do
      {:ok, %State{state | pong_pid: pong_pid}}
    else
      reason = "can not find pong process"
      Logger.error(reason)
      {:stop, reason}
    end
  end

  def cast_ping(payload \\ "") do
    GenServer.cast(__MODULE__, {:ping, payload})
  end

  def handle_cast(
        {:ping, payload},
        %State{pong_pid: pong_pid, measurements: measurements} = state
      ) do
    measurement = %Measurement{send_time: System.monotonic_time(:microsecond)}

    GenServer.cast(pong_pid, {:ping, self(), payload})

    {:noreply, %State{state | measurements: [measurement | measurements]}}
  end

  def handle_cast({:pong, _payload}, %State{measurements: [h | t]} = state) do
    measurement = %Measurement{h | recv_time: System.monotonic_time(:microsecond)}

    Logger.debug("#{(measurement.recv_time - measurement.send_time) / 1000} ms")

    {:noreply, %State{state | measurements: [measurement | t]}}
  end
end

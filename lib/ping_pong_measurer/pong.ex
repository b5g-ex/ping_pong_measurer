defmodule PingPongMeasurer.Pong do
  use GenServer
  require Logger

  defmodule State do
    defstruct ping_pid: nil
  end

  def start_link(_state) do
    {:ok, pid} = on_start = GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
    :global.register_name(__MODULE__, pid)
    on_start
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:ping, ping_pid, payload}, state) do
    GenServer.cast(ping_pid, {:pong, payload})
    {:noreply, state}
  end
end

defmodule PingPongMeasurer.Pong do
  use GenServer
  require Logger

  defmodule State do
    defstruct process_index: 1, ping_pid: nil
  end

  def start_link(process_index) when is_integer(process_index) do
    process_name = process_name(process_index)
    initial_state = %State{process_index: process_index}

    {:ok, pid} = on_start = GenServer.start_link(__MODULE__, initial_state, name: process_name)
    :global.register_name(process_name, pid)

    on_start
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:ping, ping_process_pid, payload}, state) do
    GenServer.cast(ping_process_pid, {:pong, payload})
    {:noreply, state}
  end

  defp process_name(process_index) when is_integer(process_index) do
    Module.concat(__MODULE__, "#{process_index}")
  end
end

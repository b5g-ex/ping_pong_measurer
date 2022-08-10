defmodule PingPongMeasurer do
  @moduledoc """
  Documentation for `PingPongMeasurer`.
  """

  @doc """
  connect Node

  ## Examples

      iex> PingPongMeasurer.connect("pong@127.0.0.1")
      true

  """
  @spec connect(String.t()) :: boolean() | :ignored
  def connect(name \\ "ping@127.0.0.1") when is_binary(name) do
    Node.connect(:"#{name}")
  end

  def start_pong_processes(process_count \\ 1) when is_integer(process_count) do
    ds_name = pong_supervisor_name()

    PingPongMeasurer.DynamicSupervisor.start_link(ds_name)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(ds_name, {PingPongMeasurer.Pong, process_index})
    end
  end

  def stop_pong_processes() do
    DynamicSupervisor.stop(pong_supervisor_name())
  end

  def start_ping_processes(process_count \\ 1) do
    ds_name = ping_supervisor_name()

    PingPongMeasurer.DynamicSupervisor.start_link(ds_name)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(ds_name, {PingPongMeasurer.Ping, process_index})
    end
  end

  def stop_ping_processes() do
    DynamicSupervisor.stop(ping_supervisor_name())
  end

  @doc """
  send ping to pong process parallel

  ## Examples

      iex> PingPongMeasurer.connect(100, <<1::size(800)>>) # send ping with 100 byte payload

  """
  def ping(process_count \\ 1, payload \\ "") do
    1..process_count
    |> Flow.from_enumerable()
    |> Flow.map(fn process_index -> PingPongMeasurer.Ping.cast_ping(process_index, payload) end)
    |> Enum.to_list()
  end

  defp ping_supervisor_name() do
    Module.concat(__MODULE__, Ping.DynamicSupervisor)
  end

  defp pong_supervisor_name() do
    Module.concat(__MODULE__, Pong.DynamicSupervisor)
  end
end

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

  def start_pong(process_count \\ 1) when is_integer(process_count) do
    ds_name = Module.concat(__MODULE__, Pong.DynamicSupervisor)

    [{DynamicSupervisor, strategy: :one_for_one, name: ds_name}]
    |> Supervisor.start_link(strategy: :one_for_one)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(ds_name, {PingPongMeasurer.Pong, process_index})
    end
  end

  def start_ping(process_count \\ 1) do
    ds_name = Module.concat(__MODULE__, Ping.DynamicSupervisor)

    [{DynamicSupervisor, strategy: :one_for_one, name: ds_name}]
    |> Supervisor.start_link(strategy: :one_for_one)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(ds_name, {PingPongMeasurer.Ping, process_index})
    end
  end

  defdelegate ping(process_index \\ 1, payload \\ ""), to: PingPongMeasurer.Ping, as: :cast_ping
end

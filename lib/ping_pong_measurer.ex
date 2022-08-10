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

  def start_pong() do
    PingPongMeasurer.Pong.start_link(nil)
  end

  def start_ping() do
    PingPongMeasurer.Ping.start_link(nil)
  end

  defdelegate ping(payload), to: PingPongMeasurer.Ping, as: :cast_ping
end

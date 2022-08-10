defmodule PingPongMeasurer.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(name) when is_atom(name) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: name)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

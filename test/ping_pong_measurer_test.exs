defmodule PingPongMeasurerTest do
  use ExUnit.Case
  doctest PingPongMeasurer

  test "greets the world" do
    assert PingPongMeasurer.hello() == :world
  end
end

defmodule PingPongMeasurerTest do
  use ExUnit.Case

  for process_count <- [1, 10, 100] do
    @tag :tmp_dir
    @tag :capture_log
    test "start_(pong|ping)_process with process_count: #{process_count}", %{tmp_dir: tmp_dir} do
      process_count = unquote(process_count)

      PingPongMeasurer.start_pong_processes(process_count)
      PingPongMeasurer.start_ping_processes(tmp_dir, process_count)

      PingPongMeasurer.ping()

      PingPongMeasurer.stop_pong_processes()
      PingPongMeasurer.stop_ping_processes()
    end
  end
end

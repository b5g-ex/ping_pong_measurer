defmodule PingPongMeasurerTest do
  use ExUnit.Case

  for process_count <- [1, 10, 100], payload_bytes <- [10, 100, 1000, 10000] do
    @tag :tmp_dir
    @tag :capture_log
    test "start_(pong|ping)_process with process_count: #{process_count}, payload_bytes: #{payload_bytes}",
         %{tmp_dir: tmp_dir} do
      process_count = unquote(process_count)
      payload_bits = 8 * unquote(payload_bytes)

      PingPongMeasurer.start_pong_processes(process_count)
      PingPongMeasurer.start_ping_processes(tmp_dir, process_count)

      PingPongMeasurer.ping(process_count, <<1::size(payload_bits)>>)

      PingPongMeasurer.stop_pong_processes()
      PingPongMeasurer.stop_ping_processes()
    end
  end
end

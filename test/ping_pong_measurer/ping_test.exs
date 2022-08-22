defmodule PingPongMeasurer.PingTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias PingPongMeasurer.Ping
  alias PingPongMeasurer.Pong

  describe "PingPongMeasurer.Ping" do
    @describetag :tmp_dir

    test "failed to start_supervised without Pong", %{tmp_dir: data_directory_path} do
      process_index = 0

      assert capture_log(fn ->
               {:error, _reason} = start_supervised({Ping, {data_directory_path, process_index}})
             end) =~ "cannot find pong process"
    end

    @tag :capture_log
    test "start_supervised! successfully with Pong", %{tmp_dir: data_directory_path} do
      process_index = 0

      start_supervised!({Pong, process_index})
      start_supervised!({Ping, {data_directory_path, process_index}})
    end

    @tag :capture_log
    test "call_ping to nonexistent process", %{tmp_dir: data_directory_path} do
      process_index = 0
      nonexistent_process_index = 1

      start_supervised!({Pong, process_index})
      start_supervised!({Ping, {data_directory_path, process_index}})

      assert catch_exit(Ping.call_ping(nonexistent_process_index)) ==
               {:noproc,
                {GenServer, :call,
                 [:"Elixir.PingPongMeasurer.Ping.#{nonexistent_process_index}", {:ping, ""}, 5000]}}
    end

    @tag :capture_log
    test "call_ping return :ok", %{tmp_dir: data_directory_path} do
      process_index = 0

      start_supervised!({Pong, process_index})
      start_supervised!({Ping, {data_directory_path, process_index}})

      assert :ok = Ping.call_ping(process_index)
    end

    @tag :capture_log
    test "cast_ping to nonexistent process return :ok", %{tmp_dir: data_directory_path} do
      process_index = 0
      nonexistent_process_index = 1

      start_supervised!({Pong, process_index})
      start_supervised!({Ping, {data_directory_path, process_index}})

      assert :ok = Ping.cast_ping(nonexistent_process_index)
    end

    @tag :capture_log
    test "cast_ping return :ok", %{tmp_dir: data_directory_path} do
      process_index = 0

      start_supervised!({Pong, process_index})
      start_supervised!({Ping, {data_directory_path, process_index}})

      assert :ok = Ping.cast_ping(process_index)
    end
  end
end

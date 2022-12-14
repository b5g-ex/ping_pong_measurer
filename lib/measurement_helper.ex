defmodule MeasurementHelper do
  alias PingPongMeasurer.Data

  def start_measurement(process_count \\ 1, payload_bytes \\ 10, measurement_times \\ 10)
      when process_count in [1, 10, 100] and payload_bytes in [10, 100, 1000, 10000] do
    data_directory_path = prepare_data_directory!(process_count, payload_bytes, measurement_times)

    PingPongMeasurer.start_os_info_measurement(data_directory_path)
    PingPongMeasurer.start_ping_processes(data_directory_path, process_count)

    payload_bits = 8 * payload_bytes

    for _ <- 1..measurement_times do
      PingPongMeasurer.ping(process_count, <<1::size(payload_bits)>>)
    end

    PingPongMeasurer.stop_ping_processes()
    PingPongMeasurer.stop_os_info_measurement()
  end

  def start_node(longname, cookie) when is_binary(longname) and is_atom(cookie) do
    System.cmd("epmd", ["-daemon"])
    longname |> String.to_atom() |> Node.start()
    Node.set_cookie(cookie)
  end

  defp prepare_data_directory!(process_count, payload_bytes, measurement_times) do
    data_directory_path =
      Application.get_env(:ping_pong_measurer, :data_directory_path) ||
        raise """
        You have to configure :data_directory_path in config.exs
        ex) config :ping_pong_measurer, :data_directory_path, "path/to/directory"
        """

    dt_string = Data.datetime_to_string(DateTime.utc_now())
    directory_name = "#{dt_string}_pc#{process_count}_pb#{payload_bytes}_mt#{measurement_times}"
    data_directory_path = Path.join(data_directory_path, directory_name)

    File.mkdir_p!(data_directory_path)
    data_directory_path
  end
end

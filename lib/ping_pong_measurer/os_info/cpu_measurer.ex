defmodule PingPongMeasurer.OsInfo.CpuMeasurer do
  use GenServer
  require Logger

  defmodule State do
    defstruct measurements: [], data_directory_path: nil, measurement_cycle_ms: 100
  end

  defmodule Measurement do
    defstruct measurement_time: nil, value: nil
  end

  def start_link(init_args) when is_tuple(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init({data_directory_path, measurement_cycle_ms})
      when is_binary(data_directory_path) and is_integer(measurement_cycle_ms) do
    Process.flag(:trap_exit, true)
    send(self(), :measure)

    {:ok,
     %State{data_directory_path: data_directory_path, measurement_cycle_ms: measurement_cycle_ms}}
  end

  def terminate(
        reason,
        %State{measurements: measurements, data_directory_path: data_directory_path} = _state
      ) do
    Logger.debug("#{inspect(reason)}")

    file_path = Path.join(data_directory_path, "cpu.csv")
    PingPongMeasurer.Data.save(file_path, [header() | body(measurements)])
  end

  def handle_info(
        :measure,
        %State{measurements: measurements, measurement_cycle_ms: measurement_cycle_ms} = state
      ) do
    measurement = %Measurement{measurement_time: DateTime.utc_now(), value: measure_cpu()}
    Process.sleep(measurement_cycle_ms)
    send(self(), :measure)
    {:noreply, %State{state | measurements: [measurement | measurements]}}
  end

  def measure_cpu() do
    File.read!("/proc/stat")
    |> String.split("\n")
    |> List.first()
  end

  defp header() do
    [
      "measurement_time(utc)",
      # see man 5 proc, /proc/stat
      "user",
      "nice",
      "system",
      "idle",
      "iowait",
      "irq",
      "softirq",
      "steal",
      "guest",
      "guest_nice"
    ]
  end

  defp body(measurements) when is_list(measurements) do
    Enum.reduce(measurements, [], fn measurement, rows ->
      cpu_stat_list =
        measurement.value
        |> String.split(" ", trim: true)
        # delete "cpu"
        |> List.delete_at(0)

      row = [measurement.measurement_time | cpu_stat_list]
      [row | rows]
    end)
  end
end

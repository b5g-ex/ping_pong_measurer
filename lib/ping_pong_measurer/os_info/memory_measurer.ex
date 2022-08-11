defmodule PingPongMeasurer.OsInfo.MemoryMeasurer do
  use GenServer
  require Logger

  alias NimbleCSV.RFC4180, as: CSV

  defmodule State do
    defstruct measurements: [], data_directory_path: nil
  end

  defmodule Measurement do
    defstruct measurement_time: nil, value: nil
  end

  def start_link(data_directory_path) when is_binary(data_directory_path) do
    GenServer.start_link(__MODULE__, data_directory_path, name: __MODULE__)
  end

  def init(data_directory_path) when is_binary(data_directory_path) do
    Process.flag(:trap_exit, true)
    send(self(), :measure)
    {:ok, %State{data_directory_path: data_directory_path}}
  end

  def terminate(
        reason,
        %State{measurements: measurements, data_directory_path: data_directory_path} = _state
      ) do
    Logger.debug("#{inspect(reason)}")

    [header() | body(measurements)]
    |> CSV.dump_to_stream()
    |> Enum.join()
    |> then(&File.write(Path.join(data_directory_path, "memory.csv"), &1))
  end

  def handle_info(:measure, %State{measurements: measurements} = state) do
    measurement = %Measurement{measurement_time: DateTime.utc_now(), value: measure_memory()}
    Process.sleep(1000)
    send(self(), :measure)
    {:noreply, %State{state | measurements: [measurement | measurements]}}
  end

  def handle_info({:EXIT, _port, :normal}, state) do
    # System.cmd/2 uses Port, so we have to catch the :EXIT
    # Because we set Process.flag(:trap_exit, true)
    {:noreply, state}
  end

  def measure_memory() do
    # Do not use `free` options,
    # cause `free` of busybox doesn't have options.
    {binary, 0} = System.cmd("free", [])

    binary
    |> String.split("\n")
    |> List.delete_at(0)
    |> List.first()
  end

  defp header() do
    [
      "measurement_time(utc)",
      # see man 1 free
      "total",
      "used",
      "free",
      "shared",
      "buff/cache",
      "available"
    ]
  end

  defp body(measurements) when is_list(measurements) do
    Enum.reduce(measurements, [], fn measurement, rows ->
      memory_stat_list =
        measurement.value
        |> String.split(" ", trim: true)
        # delete "Mem:"
        |> List.delete_at(0)

      row = [measurement.measurement_time | memory_stat_list]
      [row | rows]
    end)
  end
end

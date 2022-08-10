defmodule PingPongMeasurer.Data do
  alias NimbleCSV.RFC4180, as: CSV

  defmodule Measurement do
    defstruct send_time: nil, recv_time: nil
    @type t() :: %__MODULE__{send_time: integer(), recv_time: integer()}
  end

  @spec save(String.t(), [Measurement.t()]) :: :ok | {:error, :file.posix()}
  def save(file_path, measurements) do
    [header() | body(measurements)]
    |> CSV.dump_to_stream()
    |> Enum.join()
    |> then(&File.write(file_path, &1))
  end

  @doc """
  create file name

  ## Examples

      iex> datetime = DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      iex> PingPongMeasurer.Data.file_name(datetime, 100)
      "20160524132608_0100.csv"

  """
  def file_name(%DateTime{} = datetime, index) when is_integer(index) do
    datetime_string = datetime_to_string(datetime)
    index = String.pad_leading("#{index}", 4, "0")

    "#{datetime_string}_#{index}.csv"
  end

  defp datetime_to_string(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_string()
    |> then(&Regex.replace(~r/\..*$/, &1, ""))
    |> String.replace(["-", " ", ":"], "")
  end

  defp header() do
    [
      "send time[microsecond]",
      "recv time[microsecond]",
      "took time[ms]"
    ]
  end

  @spec body([Measurement.t()]) :: list()
  defp body(measurements) when is_list(measurements) do
    Enum.reduce(measurements, [], fn %Measurement{} = measurement, rows ->
      row = [
        measurement.send_time,
        measurement.recv_time,
        (measurement.recv_time - measurement.send_time) / 1000
      ]

      [row | rows]
    end)
  end
end

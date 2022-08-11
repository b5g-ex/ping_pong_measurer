defmodule PingPongMeasurer.Data do
  alias NimbleCSV.RFC4180, as: CSV

  @spec save(String.t(), [list()]) :: :ok | {:error, :file.posix()}
  def save(file_path, rows) do
    rows
    |> CSV.dump_to_stream()
    |> Enum.join()
    |> then(&File.write(file_path, &1))
  end

  def datetime_to_string(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_string()
    |> then(&Regex.replace(~r/\..*$/, &1, ""))
    |> String.replace(["-", " ", ":"], "")
  end
end

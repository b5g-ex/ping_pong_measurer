defmodule PingPongMeasurer do
  @moduledoc """
  Documentation for `PingPongMeasurer`.
  """

  alias PingPongMeasurer.OsInfo.CpuMeasurer
  alias PingPongMeasurer.OsInfo.MemoryMeasurer

  @doc """
  connect Node

  ## Examples

      iex> PingPongMeasurer.connect("pong@127.0.0.1")
      true

  """
  @spec connect(String.t()) :: boolean() | :ignored
  def connect(name \\ "ping@127.0.0.1") when is_binary(name) do
    Node.connect(:"#{name}")
  end

  def start_pong_processes(process_count \\ 1) when is_integer(process_count) do
    ds_name = pong_supervisor_name()

    PingPongMeasurer.DynamicSupervisor.start_link(ds_name)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(ds_name, {PingPongMeasurer.Pong, process_index})
    end
  end

  def stop_pong_processes() do
    DynamicSupervisor.stop(pong_supervisor_name())
  end

  def start_ping_processes(data_directory_path, process_count \\ 1)
      when is_binary(data_directory_path) do
    ds_name = ping_supervisor_name()

    PingPongMeasurer.DynamicSupervisor.start_link(ds_name)

    for process_index <- 1..process_count do
      DynamicSupervisor.start_child(
        ds_name,
        {PingPongMeasurer.Ping, {data_directory_path, process_index}}
      )
    end
  end

  def stop_ping_processes() do
    DynamicSupervisor.stop(ping_supervisor_name())
  end

  @doc """
  send ping to pong process parallel

  ## Examples

      iex> PingPongMeasurer.connect(100, <<1::size(800)>>) # send ping with 100 byte payload

  """
  def ping(process_count \\ 1, payload \\ "") do
    1..process_count
    |> Flow.from_enumerable()
    |> Flow.map(fn process_index -> PingPongMeasurer.Ping.cast_ping(process_index, payload) end)
    |> Enum.to_list()
  end

  def start_os_info_measurement(data_directory_path) when is_binary(data_directory_path) do
    ds_name = os_info_supervisor_name()
    PingPongMeasurer.DynamicSupervisor.start_link(ds_name)
    DynamicSupervisor.start_child(ds_name, {CpuMeasurer, data_directory_path})
    DynamicSupervisor.start_child(ds_name, {MemoryMeasurer, data_directory_path})
  end

  def stop_os_info_measurement() do
    DynamicSupervisor.stop(os_info_supervisor_name())
  end

  defp ping_supervisor_name() do
    Module.concat(__MODULE__, Ping.DynamicSupervisor)
  end

  defp pong_supervisor_name() do
    Module.concat(__MODULE__, Pong.DynamicSupervisor)
  end

  defp os_info_supervisor_name() do
    Module.concat(__MODULE__, OsInfo.DynamicSupervisor)
  end
end

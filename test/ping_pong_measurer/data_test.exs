defmodule PingPongMeasurer.DataTest do
  use ExUnit.Case

  doctest PingPongMeasurer.Data, only: [file_name: 2]

  alias PingPongMeasurer.Data
  alias PingPongMeasurer.Data.Measurement

  describe "save" do
    @tag :tmp_dir
    test "return :ok", %{tmp_dir: tmp_dir} do
      measurements = [
        %Measurement{send_time: 1, recv_time: 2},
        %Measurement{send_time: 3, recv_time: 4}
      ]

      file_path = Path.join(tmp_dir, "test.csv")

      assert :ok = Data.save(file_path, measurements)

      assert """
             send time[microsecond],recv time[microsecond]\r
             3,4\r
             1,2\r
             """ == File.read!(file_path)
    end
  end
end

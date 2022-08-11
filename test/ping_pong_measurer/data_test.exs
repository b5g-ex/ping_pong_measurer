defmodule PingPongMeasurer.DataTest do
  use ExUnit.Case

  alias PingPongMeasurer.Data

  describe "save" do
    @tag :tmp_dir
    test "return :ok", %{tmp_dir: tmp_dir} do
      file_path = Path.join(tmp_dir, "test.csv")
      assert :ok = Data.save(file_path, [["a", "b", "c", "d"], [1, 2, 3, 4]])

      assert """
             a,b,c,d\r
             1,2,3,4\r
             """ == File.read!(file_path)
    end
  end
end

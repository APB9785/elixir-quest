defmodule ElixirQuestWeb.PageControllerTest do
  use ElixirQuest.DataCase

  alias ElixirQuest.Utils

  test "lcm/1" do
    assert Utils.lcm([8, 8, 8]) == 8
    assert Utils.lcm([4, 8, 16]) == 16
    assert Utils.lcm([4, 8, 2]) == 8
    assert Utils.lcm([3, 10, 5]) == 30
  end
end

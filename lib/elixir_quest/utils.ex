defmodule ElixirQuest.Utils do
  @moduledoc """
  Helpers.
  """
  # alias ElixirQuest.Regions.Region
  alias ETS.Set, as: Ets

  require Logger

  def lookup_pid(registry_key) do
    [{pid, _}] = Registry.lookup(:eq_reg, registry_key)
    pid
  end

  def get_location_contents({x, y}, objects, location_index) do
    case Ets.get!(location_index, {x, y}) do
      nil -> :empty
      :rock -> :rock
      id -> object_by_id(id, objects)
    end
  end

  defp object_by_id(id, objects) do
    case Ets.get!(objects, id) do
      nil -> :empty
      object -> object
    end
  end

  def calculate_nearby_coords({x, y}) do
    for y <- (y - 5)..(y + 5)//1,
        x <- (x - 5)..(x + 5)//1,
        do: {x, y}
  end

  def adjacent_coord({x, y}, direction) do
    case direction do
      :north -> {x, y - 1}
      :south -> {x, y + 1}
      :east -> {x + 1, y}
      :west -> {x - 1, y}
    end
  end

  def distance({ax, ay}, {bx, by}) do
    x = abs(ax - bx)
    y = abs(ay - by)

    :math.sqrt(x ** 2 + y ** 2)
  end

  def lcm(nums) when is_list(nums), do: Enum.reduce(nums, &lcm/2)
  def lcm(a, b), do: div(abs(a * b), Integer.gcd(a, b))

  def solve_direction({start_x, start_y}, {destination_x, destination_y}) do
    dx = start_x - destination_x
    dy = start_y - destination_y

    if abs(dx) > abs(dy) do
      if dx > 0, do: :west, else: :east
    else
      if dy > 0, do: :north, else: :south
    end
  end
end

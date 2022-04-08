defmodule ElixirQuest.Utils do
  @moduledoc """
  Helpers.
  """
  require Logger

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

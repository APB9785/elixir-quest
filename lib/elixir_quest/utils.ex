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
      :northeast -> {x + 1, y - 1}
      :southeast -> {x + 1, y + 1}
      :northwest -> {x - 1, y - 1}
      :southwest -> {x - 1, y + 1}
    end
  end

  def distance({ax, ay}, {bx, by}) do
    x = abs(ax - bx)
    y = abs(ay - by)

    :math.sqrt(x ** 2 + y ** 2)
  end

  def solve_direction({start_x, start_y}, {destination_x, destination_y}) do
    dx = start_x - destination_x
    dy = start_y - destination_y

    if abs(dx) > abs(dy) do
      if dx > 0, do: :west, else: :east
    else
      if dy > 0, do: :north, else: :south
    end
  end

  def parse_direction(key) do
    cond do
      key == "ArrowLeft" or key == "a" -> :west
      key == "ArrowRight" or key == "d" -> :east
      key == "ArrowUp" or key == "w" -> :north
      key == "ArrowDown" or key == "s" -> :south
      :otherwise -> :error
    end
  end

  def merge_directions(new_direction, current_direction)

  def merge_directions(:error, current_direction), do: current_direction
  def merge_directions(new_direction, nil), do: new_direction
  def merge_directions(:west, :north), do: :northwest
  def merge_directions(:west, :south), do: :southwest
  def merge_directions(:east, :north), do: :northeast
  def merge_directions(:east, :south), do: :southeast
  def merge_directions(:south, :east), do: :southeast
  def merge_directions(:south, :west), do: :southwest
  def merge_directions(:north, :east), do: :northeast
  def merge_directions(:north, :west), do: :northwest
  def merge_directions(_, current_direction), do: current_direction

  def remove_direction(to_remove, current_direction)

  def remove_direction(:error, current_direction), do: current_direction

  def remove_direction(:south, current_direction) do
    case current_direction do
      :south -> nil
      :southeast -> :east
      :southwest -> :west
      _ -> current_direction
    end
  end

  def remove_direction(:north, current_direction) do
    case current_direction do
      :north -> nil
      :northeast -> :east
      :northwest -> :west
      _ -> current_direction
    end
  end

  def remove_direction(:east, current_direction) do
    case current_direction do
      :east -> nil
      :southeast -> :south
      :northeast -> :north
      _ -> current_direction
    end
  end

  def remove_direction(:west, current_direction) do
    case current_direction do
      :west -> nil
      :northwest -> :north
      :southwest -> :south
      _ -> current_direction
    end
  end
end

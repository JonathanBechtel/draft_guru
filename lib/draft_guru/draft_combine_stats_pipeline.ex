defmodule DraftGuru.DraftCombineStatsPipeline do
  @moduledoc """
  Module for data pipeline that moves draft combine data to database
  """

  @doc """
  Cleans incoming player map for data inconsistencies

  Particularly parsing differing null values ("-", "_", "", etc)

  And assisting with data type conversions
  """
  def parse_map(player_map) do
    updated_map =
      player_map
      |> Map.update("draft_year", nil, &parse_value/1)
      |> Map.update("hand_length", nil, &parse_string/1)
      |> Map.update("hand_width", nil, &parse_string/1)

    {:ok, updated_map}
  end

  def parse_value(value) do
    case value do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      value when is_float(value) -> trunc(value)
      _ -> value
    end
  end

  def parse_string(value) do
    case value do
      "-" -> nil
      "" -> nil
      value when is_binary(value) -> String.to_float(value)
      _ -> value
    end
  end

end

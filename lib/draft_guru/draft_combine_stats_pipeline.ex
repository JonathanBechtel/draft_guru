defmodule DraftGuru.DraftCombineStatsPipeline do
  @moduledoc """
  Module for data pipeline that moves draft combine data to database
  """
  alias DraftGuru.Players
  alias DraftGuru.PlayerIDLookups
  alias DraftGuru.PlayerCombineStats
  alias DraftGuru.Players.Player
  alias DraftGuru.Players.PlayerIdLookup

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

  @doc """
  Uses a fuzzy match to see if there's an existing player
  inside the player_canonical_table
  """
  def check_for_canonical_player_record(player_map) do
    canonical_player_record = case Players.get_player_by_name(player_map) do

      %Player{} = player -> {:ok, true, player}
      nil -> {:error, false, :not_found}
      _ -> {:error, false, :not_found}
    end

    {:ok, canonical_player_record}
  end

  @doc """
  Takes the result from check_for_canonical_player_record
  and uses that to determine whether or not there's a
  matching player_id_record
  """
  def check_for_player_id_lookup_record(canonical_player_result) do
    player_id_record = case canonical_player_result do
      {:ok, true, player} ->
        case PlayerIDLookups.get_lookup_by_player_id(player.id) do
        %PlayerIdLookup{} = player_id -> {:ok, true, player_id}
        nil ->
            {:error, false, :not_found}
      end

      {:error, false, :not_found} -> {:error, false, :not_found}
    end

    {:ok, player_id_record}
  end

  def update_player_id_lookup_table(player_map, canonical_player_result, player_id_result) do
      {_, is_canonical_player, canonical_record} = canonical_player_result
      {_, has_player_id_lookup, id_record} = player_id_result

      possible_canonical_player = if not is_canonical_player do
        Players.create_player(%{"suffix" => _suffix,
              "first_name" => _first_name,
              "middle_name" => _middle_name,
              "last_name" => _last_name,
              "draft_year" => _draft_year} = player_map)
      else
        true
      end

      {is_canonical_player, canonical_record} = case possible_canonical_player do
        {:ok, record} -> {true, record}
        {:error, _message} -> {false, nil}
        _ -> {is_canonical_player, canonical_record}
      end

      cond do
        is_canonical_player and not has_player_id_lookup ->

          {:ok, _record} = PlayerIDLookups.create_id_lookup(%{
            data_source: "nba.com/stats/draft",
            data_source_id: player_map["player_slug"],
            player_id: canonical_record.id
          })

        is_canonical_player and has_player_id_lookup ->
          # warn that records is being overwritten
          IO.puts("WARNING:  Overwriting record for player with slug #{player_map["player_slug"]}")
          {:ok, _record} = PlayerIDLookups.update_player_id_lookup(id_record, %{
            data_source: "nba.com/stats/draft",
            data_source_id: player_map["player_slug"],
            player_id: canonical_record.id
          })

        true -> IO.puts("no existing player, no id lookup, passing")
      end

      {:ok, canonical_record}
    end

    def insert_updated_map_into_draft_combine_stats_table(player_map,
            canonical_record) do

        case PlayerCombineStats.create_player_combine_stats(%{
          position: player_map["position"],
          player_slug: player_map["player_slug"],
          lane_agility_time: player_map["lane_agility_time"],
          shuttle_run: player_map["shuttle_run"],
          three_quarter_sprint: player_map["three_quarter_sprint"],
          standing_vertical_leap: player_map["standing_vertical_leap"],
          max_vertical_leap: player_map["max_vertical_leap"],
          max_bench_press_repetitions: player_map["max_bench_press_repetitions"],
          height_w_shoes: player_map["height_w_shoes"],
          height_wo_shoes: player_map["height_wo_shoes"],
          body_fat_pct: player_map["body_fat_pct"],
          hand_length: player_map["hand_length"],
          hand_length_inches: player_map["hand_length_inches"],
          hand_width: player_map["hand_width"],
          hand_width_inches: player_map["hand_width_inches"],
          standing_reach: player_map["standing_reach"],
          standing_reach_inches: player_map["standing_reach_inches"],
          weight_lbs: player_map["weight_lbs"],
          wingspan: player_map["wingspan"],
          wingspan_inches: player_map["wingspan_inches"],
          height_wo_shoes_inches: player_map["height_wo_shoes_inches"],
          height_w_shoes_inches: player_map["height_w_shoes_inches"],
          player_id: canonical_record.id
        }) do
          {:ok, record} ->
            IO.puts("Successfully inserted record for player: #{player_map["player_slug"]}")
            {:ok, record}
          {:error, _changeset} -> IO.puts("Unsuccessful insertion for player: #{player_map["player_slug"]}")
        end
      end

  def process_draft_combine_stats_map(player_map) do
    {:ok, updated_map} = parse_map(player_map)
    {:ok, canonical_player_result} = check_for_canonical_player_record(updated_map)
    {:ok, player_id_result} = check_for_player_id_lookup_record(canonical_player_result)
    {:ok, updated_canonical_record} = update_player_id_lookup_table(updated_map, canonical_player_result, player_id_result)
    {:ok, _record} = insert_updated_map_into_draft_combine_stats_table(updated_map, updated_canonical_record)
    {:ok, :record_inserted_successfully}
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

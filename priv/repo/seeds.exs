
import DraftGuru.DataLoader, only: [create_dataset: 1]
alias DraftGuru.Players
alias DraftGuru.Players.Player
alias DraftGuru.PlayerIDLookups
alias DraftGuru.Players.PlayerIdLookup
alias DraftGuru.PlayerCombineStats

defmodule DraftGuru.DraftCombineStatsSeed do

  # load in player data
  def seed_data(filepath) do
    player_data = create_dataset(filepath)
    process_player_data(player_data)
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

  def process_player_data(player_data) do
    Enum.map(player_data, fn player_map ->

      # clean incoming values
      player_map = Map.put(player_map,
                  "draft_year",
                  parse_value(player_map["draft_year"]))

      player_map = Map.put(player_map,
                   "hand_width",
                   parse_string(player_map["hand_width"]))

      player_map = Map.put(player_map,
                  "hand_length",
                  parse_string(player_map["hand_length"]))

      # check to see if this player exists inside the canonical table
      # store the player information if it does
      canonical_player_record = case Players.get_player_by_name(player_map) do
          %Player{} = player -> {:ok, true, player}
          nil -> {:error, false, :not_found}
          _ -> {:error, false, :not_found}
        end

      IO.inspect(canonical_player_record, label: "canonical player record")

      # if there is a canonical player record,
      # check to see if there's a corresponding player id record
      player_id_record = case canonical_player_record do
        {:ok, true, player} ->
          case PlayerIDLookups.get_lookup_by_player_id(player.id) do
          %PlayerIdLookup{} = player_id -> {:ok, true, player_id}
        nil ->
            {:error, false, :not_found}
        end

        {:error, false, :not_found} ->
          IO.puts("no value at all")
          {:error, false, :not_found}
      end

      {_, is_canonical_player, canonical_record} = canonical_player_record
      {_, has_player_id_lookup, id_record} = player_id_record

      # add the player to the canonical player table if they do
      # not currently exist -- note success of the transacation

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

      # finally, add the player to the draft combine stats table
      try do
        {:ok, _record} = PlayerCombineStats.create_player_combine_stats(%{
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
        })
        rescue
          e -> IO.inspect(e, label: "error adding player to database: ")
      end
    end)
  end
end

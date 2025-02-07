# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DraftGuru.Repo.insert!(%DraftGuru.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import DraftGuru.DataLoader, only: [create_dataset: 1]
alias DraftGuru.Players
alias DraftGuru.PlayerID

defmodule DraftGuru.DraftCombineStatsSeed do
alias DraftGuru.Players.PlayerIdLookup
alias ExUnit.FailuresManifest

  # load in player data
  def seed_data(filepath) do
    player_data = create_dataset(filepath)
    process_player_data(player_data)
  end

  def process_player_data(player_data) do
    Enum.map(player_data, fn player_map ->

      # check to see if this player exists inside the canonical table
      # store the player information if it does
      canonical_player_record = case Players.get_player_by_name(player_map) do
          %Player{} = player -> {:ok, true, player}
          nil -> {:error, false, :not_found}
        end

      # if there is a canonical player record,
      # check to see if there's a corresponding player id record
      player_id_record = case canonical_player_record do
        {:ok, true, player} -> case PlayerID.get_lookup_by_player_id!(player.id) do
          %PlayerIdLookup{} = player -> {:ok, true, player_id}
          nil -> {:error, false, :not_found}
        end
      end

      {_, is_canonical_player, canonical_record} = canonical_player_record
      {_, has_player_id_lookup, id_record} = player_id_record

      # add the player to the canonical player table if they do
      # not currently exist -- note success of the transacation
      if not is_canonical_player do
        is_canonical_player = case Players.create_player(%{"suffix" => suffix,
              "first_name" => first_name,
              "middle_name" => middle_name,
              "last_name" => last_name,
              "draft_year" => draft_year} = player_map) do
                {:ok, %Player{}} -> true
                _ -> false
              end
      end

      cond do
        is_canonical_player and not has_player_id_lookup ->
          {:ok, record} = PlayerID.create_id_lookup(%{
            data_source: "nba.com/stats/draft",
            data_source_id: player_map["player_slug"],
            player_id: canonical_record.id
          })

        is_canonical_player and has_player_id_lookup ->
          # warn that records is being overwritten
          IO.puts("WARNING:  Overwriting record for player with slug #{player_map["player_slug"]}")
          {:ok, record} = PlayerID.update_player_id_lookup(PlayerIdLookup, %{
            data_source: "nba.com/stats/draft",
            data_source_id: player_map["player_slug"],
            player_id: canonical_record.id
          })
      end

      # finally, add the player to the draft combine stats table
      {:ok, record} = PlayerCombineStats.create_player(%{
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
        standing_reach_inches: player_map["standing_reach"],
        weight_lbs: player_map["weight_lbs"],
        wingspan: player_map["wingspan"],
        wingspan_inches: player_map["wingspan_inches"],
        height_wo_shoes_inches: player_map["height_wo_shoes_inches"],
        height_w_shoes_inches: player_map["height_w_shoes_inches"],
        player_id: canonical_record.id
      })
    end)
  end

  # check to see if a f
end

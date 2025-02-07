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

defmodule DraftGuru.DraftCombineStatsSeed do
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
        {:ok, true, player} -> case PlayerID.get_player!(player.id) do
          %PlayerID{} = player -> {:ok, true, player_id}
          nil -> {:error, false, :not_found}
        end
      end

    end)
  end

  # check to see if a f
end

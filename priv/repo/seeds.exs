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

  # load in player data
  def seed_data(filepath) do
    player_data = create_dataset(filepath)
  end

  def process_player_data(player_data) do
    Enum.map(player_data, fn player_map ->
        case Players.get_player_by_name(player_map) do
          _ -> :ok
        end
    end)
  end

  # check to see if a f
end

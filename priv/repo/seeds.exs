
import DraftGuru.DataLoader, only: [create_dataset: 1]
import DraftGuru.DraftCombineStatsPipeline, only: [process_draft_combine_stats_map: 1]
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

    def process_player_data(player_data) do
      Enum.each(player_data, fn player_map ->
        {:ok, message} = process_draft_combine_stats_map(player_map)
    end)
  end
end

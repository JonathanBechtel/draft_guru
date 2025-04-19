
import DraftGuru.DataLoader, only: [create_dataset: 1]
import DraftGuru.DraftCombineStatsPipeline, only: [process_draft_combine_stats_map: 1]

defmodule DraftGuru.DraftCombineStatsSeed do

    # load in player data
    def seed_data(filepath) do
      player_data = create_dataset(filepath)

      process_player_data(player_data)
    end

    def process_player_data(player_data) do
      Enum.each(player_data, fn player_map ->

      IO.inspect(player_map, label: player_map)

      try do
        case process_draft_combine_stats_map(player_map) do
          {:ok, message} -> IO.puts(message)
          _ -> IO.puts("Could not update record for player: #{player_map["player_slug"]}")
        end
      rescue
        exception ->
          IO.puts("An error occurred processing player: #{player_map["player_slug"]}")
          IO.inspect(exception)
          IO.puts(Exception.format(:error, e, __STACKTRACE__))
        end
    end)
  end
end

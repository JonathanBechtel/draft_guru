
import DraftGuru.DataLoader, only: [create_dataset: 1]
import DraftGuru.DraftCombineStatsPipeline, only: [process_draft_combine_stats_map: 1]

defmodule DraftGuru.DraftCombineStatsSeed do

  def seed_data(filepath) do
    filepath
    |> create_dataset()
    # Use Enum.map and track results, or keep Enum.each if you only want side effects (IO.puts)
    |> Enum.each(&process_player/1)
    # Consider returning something more meaningful like counts of success/failure
    :ok
  end

  defp process_player(player_map) do
    player_slug = Map.get(player_map, "player_slug", "MISSING_SLUG_IN_RAW_DATA") # Get slug early for logging
    case process_draft_combine_stats_map(player_map) do
      {:ok, msg} ->
        IO.puts(msg) # Already includes slug
      # Capture specific error types if needed, or just log the generic failure
      {:error, reason_msg} ->
        # The pipeline function now does more detailed logging for transaction/validation errors
        IO.puts("Could not process record for #{player_slug}. Reason: #{reason_msg}")
     # Remove the broad rescue or make it more specific if truly needed
     # rescue
     #   e in Ecto.ConstraintError -> IO.puts("Constraint error processing #{player_slug} – #{inspect(e)}") # Example
     #   e -> IO.puts("Unexpected error processing #{player_slug} – #{inspect(e)}")
     #        IO.puts(Exception.format(:error, e, __STACKTRACE__)) # Keep stacktrace for unexpected
    end
  end
end

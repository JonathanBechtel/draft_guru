# lib/draft_guru/seeds/draft_combine_stats_seed.ex
defmodule DraftGuru.DraftCombineStatsSeed do
  @moduledoc """
    Used to seed the table player_combine_stats

    This is for building the application via Docker.

    This replicates the same code in the seeds.exs file, which is only suitable
    for local development

    If doing Docker based deployments, best to put all future seeds here
    instead
  """
  import DraftGuru.DataLoader, only: [create_dataset: 1]
  import DraftGuru.DraftCombineStatsPipeline,
         only: [process_draft_combine_stats_map: 1]

  @spec seed_data(Path.t()) :: :ok
  def seed_data(filepath) do
    filepath
    |> create_dataset()
    |> Enum.each(&process_player/1)
  end

  ## ---

  defp process_player(player_map) do
    case process_draft_combine_stats_map(player_map) do
      {:ok, msg} -> IO.puts(msg)
      _other     -> IO.puts("Could not update record for #{player_map["player_slug"]}")
    end
  rescue
    e -> IO.puts("Error processing #{player_map["player_slug"]} – #{inspect(e)}")
  end
end

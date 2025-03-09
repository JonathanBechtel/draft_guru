defmodule DraftGuru.Repo.Migrations.RemovePlayerCombineStatsUniquePlayerIdIndex do
  use Ecto.Migration

  def up do
    drop unique_index(:player_combine_stats, [:player_id], name: :player_combine_stats_unique_player_id_index)
  end

  def down do
    create unique_index(:player_combine_stats, [:player_id], name: :player_combine_stats_unique_player_id_index)
  end
end

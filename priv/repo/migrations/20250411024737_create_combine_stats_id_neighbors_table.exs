defmodule DraftGuru.Repo.Migrations.CreateCombineStatsIdNeighborsTable do
  use Ecto.Migration

  def change do
    alter table(:player_combine_stats_neighbors) do
      add :player_combine_stats_id, references(:player_combine_stats, on_delete: :delete_all), null: false
    end
  end
end

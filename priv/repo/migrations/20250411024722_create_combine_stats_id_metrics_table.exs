defmodule DraftGuru.Repo.Migrations.CreateCombineStatsIdMetricsTable do
  use Ecto.Migration

  def change do
    alter table(:player_combine_stats_metrics) do
      add :player_combine_stats_id, references(:player_combine_stats, on_delete: :delete_all), null: false
    end
  end
end

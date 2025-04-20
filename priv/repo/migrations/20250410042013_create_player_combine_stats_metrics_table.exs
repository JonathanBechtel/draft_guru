defmodule DraftGuru.Repo.Migrations.CreatePlayerCombineStatsMetricsTable do
  use Ecto.Migration

  def change do
    create table(:player_combine_stats_metrics) do
      add :player_id, references(:player_canonical, on_delete: :delete_all), null: false
      add :measurement_name, :string, null: false
      add :measurement_category, :string, null: false
      add :comparison_context, :string, null: false
      add :position_only, :boolean, default: false, null: false
      add :position_context, :string, null: false
      add :calc_year, :integer, null: false
      add :metric_type, :string, null: false
      add :metric_value, :float, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:player_combine_stats_metrics, [:player_id, :measurement_name, :comparison_context, :position_context, :calc_year, :metric_type],
           name: :player_combine_stats_metrics_unique_index)
    create index(:player_combine_stats_metrics, [:player_id, :calc_year], name: :player_combine_stats_metrics_player_id_index)
  end
end

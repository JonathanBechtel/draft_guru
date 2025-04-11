defmodule DraftGuru.Repo.Migrations.CreatePlayerCombineStatsNeighbors do
  use Ecto.Migration

  def change do
    create table(:player_combine_stats_neighbors) do
      add :player_id, references(:player_canonical, on_delete: :delete_all), null: false
      add :nn_player_id, references(:player_canonical, on_delete: :delete_all), null: false
      add :measurement_category, :string, null: false
      add :comparison_context, :string, null: false
      add :position_context, :string, null: false
      add :calc_year, :integer, null: false
      add :position_only, :boolean, default: false, null: false
      add :nn_rank, :integer, null: false
      add :nn_distance, :float, null: false
      add :nn_distance_scaled, :float, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:player_combine_stats_neighbors, [:player_id, :nn_player_id, :calc_year], name: :player_combine_stats_neighbors_unique_index)
    create unique_index(:player_combine_stats_neighbors, [:player_id, :measurement_category, :comparison_context, :position_context, :calc_year, :nn_rank], name: :player_combine_stats_neighbors_measurement_category_index)
  end
end

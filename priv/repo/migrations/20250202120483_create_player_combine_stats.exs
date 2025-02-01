defmodule DraftGuru.Repo.Migrations.CreatePlayerCombineStats do
  use Ecto.Migration

  def change do
    create table(:player_combine_stats) do
      add :position, :string
      add :player_slug, :string, null: false
      add :lane_agility_time, :float
      add :shuttle_run, :float
      add :three_quarter_sprint, :float
      add :standing_vertical_leap, :float
      add :max_vertical_leap, :float
      add :max_bench_press_repetitions, :float
      add :height_w_shoes, :string
      add :height_wo_shoes, :string
      add :body_fat_pct, :float
      add :hand_length, :string
      add :hand_length_inches, :float
      add :hand_width, :string
      add :hand_width_inches, :float
      add :standing_reach, :string
      add :standing_reach_inches, :float
      add :weight_lbs, :float
      add :wingspan, :string
      add :wingspan_inches, :float
      add :height_w_shoes_inches, :float
      add :height_wo_shoes_inches, :float

      add :player_id, references(:player_canonical, on_delete: :delete_all), null: false

      timestamps(utc: :datetime)
    end
    create unique_index(:player_combine_stats, [:player_slug],
          name: :player_combine_stats_unique_player_slug_index)
    create unique_index(:player_combine_stats, [:player_id],
          name: :player_combine_stats_unique_player_id_index)
  end
end

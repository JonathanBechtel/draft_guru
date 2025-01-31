defmodule DraftGuru.Players.PlayerCombineStats do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player_combine_stats" do
    field :position, :string
    field :player_slug, :string
    field :lane_agility_time, :float
    field :shuttle_run, :float
    field :three_quarter_sprint, :float
    field :standing_vertical_leap, :float
    field :max_vertical_leap, :float
    field :max_bench_press_repetitions, :float
    field :height_w_shoes, :string
    field :height_wo_shoes, :string
    field :body_fat_pct, :float
    field :hand_length, :string
    field :hand_length_inches, :float
    field :hand_width, :string
    field :hand_width_inches, :float
    field :standing_reach, :string
    field :standing_reach_inches, :string
    field :weight_lbs, :float
    field :wingspan, :string
    field :wingspan_inches, :float
    field :height_w_shoes_inches, :float
    field :height_wo_shoes_inches, :float

    belongs_to :player_canonical, DraftGuru.Players.Player,
      foreign_key: :player_id,
      on_replace: :delete

    timestamps(utc: :datetime)
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [
      :position,
      :player_slug,
      :lane_agility_time,
      :shuttle_run,
      :three_quarter_sprint,
      :standing_vertical_leap,
      :max_vertical_leap,
      :max_bench_press_repetitions,
      :height_w_shoes,
      :body_fat_pct,
      :hand_length,
      :hand_length_inches,
      :hand_width,
      :hand_width_inches,
      :standing_reach,
      :standing_reach_inches,
      :weight_lbs,
      :wingspan,
      :wingspan_inches,
      :height_w_shoes_inches,
      :height_wo_shoes_inches,
      :player_id])
    |> validate_required([
            :position,
            :player_slug,
            :position,
            :player_slug,
            :lane_agility_time,
            :shuttle_run,
            :three_quarter_sprint,
            :standing_vertical_leap,
            :max_vertical_leap,
            :max_bench_press_repetitions,
            :height_w_shoes,
            :body_fat_pct,
            :hand_length,
            :hand_length_inches,
            :hand_width,
            :hand_width_inches,
            :standing_reach,
            :standing_reach_inches,
            :weight_lbs,
            :wingspan,
            :wingspan_inches,
            :height_w_shoes_inches,
            :height_wo_shoes_inches,
            :player_id])
  end
end

defmodule DraftGuru.Players.PlayerCombineStat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
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
    field :hand_length, :float
    field :hand_length_inches, :float
    field :hand_width, :float
    field :hand_width_inches, :float
    field :standing_reach, :string
    field :standing_reach_inches, :float
    field :weight_lbs, :float
    field :wingspan, :string
    field :wingspan_inches, :float
    field :height_w_shoes_inches, :float
    field :height_wo_shoes_inches, :float
    field :draft_year, :integer
    field :player_name, :string

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
      :height_wo_shoes,
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
      :draft_year,
      :player_name,
      :player_id])
    |> validate_required([
            :player_slug,
            :player_name,
            :draft_year])
    |> unique_constraint(:player_slug,
        name: :player_combine_stats_unique_player_slug_index,
        message: "The player slug already exists")
    |> validate_inclusion(:draft_year, 1950..2100,
        message: "Must be between 1950 and 2100",
        allow_nil: true)
  end
end

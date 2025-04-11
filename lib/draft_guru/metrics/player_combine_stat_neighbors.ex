defmodule DraftGuru.Metrics.PlayerCombineStatNeighbors do
  @moduledoc """
  The PlayerCombineStatNeighbors context. Handles player combine stat neighbors.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @measurement_categories ["anthropometric", "performance"]
  @comparison_categories ["draft_current", "draft_historical", "nba_current", "nba_historical"]

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "player_combine_stats_neighbors" do
    field :measurement_category, :string
    field :comparison_context, :string
    field :position_context, :string
    field :calc_year, :integer
    field :position_only, :boolean, default: false
    field :nn_rank, :integer
    field :nn_distance, :float
    field :nn_distance_scaled, :float


    belongs_to :player_canonical, DraftGuru.Players.Player,
      foreign_key: :player_id,
      type: :id

    belongs_to :nn_player_canonical, DraftGuru.Players.Player,
      foreign_key: :nn_player_id,
      type: :id

    belongs_to :player_combine_stats, DraftGuru.Players.PlayerCombineStat,
      foreign_key: :player_combine_stats_id,
      type: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [
      :player_id,
      :nn_player_id,
      :measurement_category,
      :comparison_context,
      :position_context,
      :calc_year,
      :position_only,
      :nn_rank,
      :nn_distance,
      :nn_distance_scaled
    ])
    |> validate_required([
      :player_id,
      :nn_player_id,
      :measurement_category,
      :comparison_context,
      :position_context,
      :calc_year,
      :position_only,
      :nn_rank,
      :nn_distance,
      :nn_distance_scaled
    ])
    |> validate_number(:nn_rank, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_inclusion(:measurement_category, @measurement_categories)
    |> validate_inclusion(:comparison_context, @comparison_categories)
    |> validate_number(:nn_distance_scaled, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    # TO DO:  add more validations for position context
  end
end

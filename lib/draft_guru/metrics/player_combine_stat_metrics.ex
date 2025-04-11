defmodule DraftGuru.Metrics.PlayerCombineStatsMetrics do

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @comparison_categories ["draft_current", "draft_historical", "nba_current", "nba_historical"]
  @measurement_categories ["anthropometric", "performance"]
  @metric_categories ["z_score", "rank", "percentile"]

  # TO DO:  add these for position_context, measurement name after data manipulation

  schema "player_combine_stats_metrics" do

    field :measurement_name, :string
    field :measurement_category, :string
    field :comparison_context, :string
    field :position_context, :string
    field :calc_year, :integer
    field :position_only, :boolean, default: false
    field :metric_type, :integer
    field :metric_value, :float

    belongs_to :player_canonical, DraftGuru.Players.Player,
      foreign_key: :player_id,
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
      :measurement_name,
      :measurement_category,
      :comparison_context,
      :position_only,
      :position_context,
      :calc_year,
      :metric_type,
      :metric_value,
    ])
    |> validate_required([
      :player_id,
      :measurement_name,
      :measurement_category,
      :comparison_context,
      :position_only,
      :position_context,
      :calc_year,
      :metric_type,
      :metric_value,
    ])
    |> validate_percentile_value()
    |> validate_inclusion(:comparison_context, @comparison_categories)
    |> validate_inclusion(:measurement_category, @measurement_categories)
    |> validate_inclusion(:metric_type, @metric_categories)
  end

  @doc """
  Validates that metric_value is between 0 and 100 when metric_type is percentile.
  """
  def validate_percentile_value(changeset) do
    metric_type = get_field(changeset, :metric_type)

    if metric_type == "percentile" do
      validate_number(changeset, :metric_value,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 100,
        message: "percentile value must be between 0 and 100"
      )
    else
      changeset
    end
  end
end

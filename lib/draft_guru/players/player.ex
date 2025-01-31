defmodule DraftGuru.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "player_canonical" do
    field :suffix, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :draft_year, :integer

    timestamps(type: :utc_datetime)

    has_many :id_lookups, DraftGuru.Players.PlayerIdLookup, foreign_key: :player_id
    has_one :player_combine_stats, DraftGuru.Players.PlayerCombineStats, foreign_key: :player_id
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:first_name, :middle_name, :last_name, :suffix, :draft_year])
    |> validate_required([:first_name, :last_name])
    |> validate_inclusion(:draft_year, 1950..2100, message: "Must be between 1950 and 2100", allow_nil: true)
  end
end

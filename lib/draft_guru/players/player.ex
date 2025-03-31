defmodule DraftGuru.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "player_canonical" do
    field :suffix, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string

    timestamps(utc: :datetime)

    has_many :id_lookups, DraftGuru.Players.PlayerIdLookup, foreign_key: :player_id
    has_many :player_combine_stats, DraftGuru.Players.PlayerCombineStat, foreign_key: :player_id
    has_one :player_info, DraftGuru.Players.PlayerInfo, foreign_key: :player_id
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:first_name, :middle_name, :last_name, :suffix])
    |> validate_required([:first_name, :last_name])
  end
end

defmodule DraftGuru.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player_canonical" do
    field :id, :integer
    field :suffix, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :draft_year, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:id, :first_name, :middle_name, :last_name, :suffix, :draft_year])
    |> validate_required([:id, :first_name, :middle_name, :last_name, :suffix, :draft_year])
  end
end

defmodule DraftGuru.Players.PlayerIdLookup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "player_id_lookup" do
    field :data_source, :string
    field :data_source_id, :string

    belongs_to :player, DraftGuru.Players.Player,
      foreign_key: :player_id,

      on_replace: :delete

    timestamps(utc: :datetime)
  end

  @doc false
  def changeset(lookup, attrs) do
    lookup
    |> cast(attrs, [:data_source, :data_source_id, :player_id])
    |> validate_required([:data_source, :data_source_id, :player_id])
    |> unique_constraint(:player_id_lookup,
                        name: :player_id_lookup_unique_data_source_data_source_id_index,
                        message: "data source name and data source id already exist")
  end
end

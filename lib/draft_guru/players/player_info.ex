# lib/draft_guru/players/player_info.ex
defmodule DraftGuru.Players.PlayerInfo do
  use Ecto.Schema
  import Ecto.Changeset
  alias DraftGuru.Players.Player

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id
  schema "player_info" do
    field :birth_date, :date
    field :school, :string
    field :league, :string
    field :college_year, :string
    field :headshot_path, :string
    field :stylized_image_path, :string
    field :is_active, :boolean, default: false
    field :played_in_nba, :boolean, default: false

    belongs_to :player_canonical, Player,
      foreign_key: :player_id,
      type: :id # Ensure this matches the type of player_canonical.id


    # Virtual fields for image uploads
    # These fields are not stored in the database but are used for file uploads
    field :headshot, :any, virtual: true
    field :stylized_image, :any, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player_info, attrs) do

    player_info
    |> cast(attrs, [
      :birth_date,
      :school,
      :league,
      :college_year,
      :player_id,
      :headshot_path,
      :stylized_image_path,
      :is_active,
      :played_in_nba
    ])
    |> validate_required([:player_id])
    |> unique_constraint(:player_id, name: :player_info_player_id_unique_index, message: "Information for this player already exists")
  end
end

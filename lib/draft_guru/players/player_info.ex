# lib/draft_guru/players/player_info.ex
defmodule DraftGuru.Players.PlayerInfo do
  use Ecto.Schema
  import Ecto.Changeset
  use Waffle.Ecto.Schema
  alias DraftGuru.Players.Player
  alias DraftGuru.ImageUploader

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id
  schema "player_info" do
    # Fields
    field :birth_date, :date
    field :school, :string
    field :league, :string
    field :college_year, :string
    field :headshot_path, :string
    field :stylized_image_path, :string

    # Associations
    belongs_to :player_canonical, Player,
      foreign_key: :player_id,
      type: :id # Ensure this matches the type of player_canonical.id

    # Waffle attachment fields
    # *** Put the :uploader option back here ***
    field :headshot, ImageUploader.Type,  virtual: true
    field :stylized_image, ImageUploader.Type,  virtual: true

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
      :headshot_path,
      :stylized_image_path,
      :player_id
    ])
    # *** Revert cast_attachments to use a simple list of atoms ***
    |> cast_attachments(attrs, [:headshot, :stylized_image])
    |> validate_required([:player_id])
    |> unique_constraint(:player_id, name: :player_info_player_id_unique_index, message: "already has player info")
  end
end

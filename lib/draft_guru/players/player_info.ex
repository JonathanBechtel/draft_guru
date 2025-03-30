# lib/draft_guru/players/player_info.ex
defmodule DraftGuru.Players.PlayerInfo do
  use Ecto.Schema
  import Ecto.Changeset

  alias DraftGuru.Players.Player

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id
  schema "player_info" do
    # Fields
    field :school, :string
    field :league, :string
    field :college_year, :string
    field :headshot_path, :string
    field :stylized_image_path, :string

    # Associations
    belongs_to :player_canonical, Player,
      foreign_key: :player_id,
      type: :id # Ensure this matches the type of player_canonical.id

    # Virtual fields for uploads
    field :headshot, :any, virtual: true
    field :stylized_image, :any, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player_info, attrs) do
    player_info
    |> cast(attrs, [
      :school,
      :league,
      :college_year,
      :headshot_path,
      :stylized_image_path,
      :player_id # Important: Allow casting player_id on creation
    ])
    |> cast_attachments(attrs, [:headshot, :stylized_image]) # Use Ecto's built-in attachment handling
    |> validate_required([:player_id])
    |> validate_number(:birth_year,
      greater_than_or_equal_to: 1950,
      less_than_or_equal_to: :timer.now_to_universal_time() |> elem(0) |> :calendar.gregorian_years(), # Ensure birth year is reasonable
      message: "must be a valid year"
      )
    |> unique_constraint(:player_id, name: :player_info_player_id_unique_index, message: "already has player info")
  end
end

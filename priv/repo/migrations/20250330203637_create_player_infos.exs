# priv/repo/migrations/YYYYMMDDHHMMSS_create_player_infos.exs
defmodule DraftGuru.Repo.Migrations.CreatePlayerInfos do
  use Ecto.Migration

  def change do
    create table(:player_info) do
      # Biographical fields
      add :school, :string
      add :league, :string, null: false
      add :college_year, :string # e.g., "Freshman", "Sophomore", "International", "G-League Ignite"

      # Image paths (relative to the configured upload directory)
      add :headshot_path, :string
      add :stylized_image_path, :string

      # Foreign key to player_canonical (enforces 1:1)
      add :player_id, references(:player_canonical, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Ensure one player_info record per player_canonical
    create unique_index(:player_info, [:player_id], name: :player_info_player_id_unique_index)
  end
end

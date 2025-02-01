defmodule DraftGuru.Repo.Migrations.CreatePlayerIdLookup do
  use Ecto.Migration

  def change do
    create table(:player_id_lookup) do
      add :data_source, :string, null: false
      add :data_source_id, :string, null: false
      # Our foreign key to player_canonical. Using :delete_all so that any
      # associated rows in this table are removed if the Player itself is removed.
      add :player_id, references(:player_canonical, on_delete: :delete_all), null: false

      timestamps(utc: :datetime)
    end

    create index(:player_id_lookup, [:player_id])
    create unique_index(:player_id_lookup,
                [:data_source, :data_source_id],
                name: :player_id_lookup_unique_data_source_data_source_id_index)
  end
end

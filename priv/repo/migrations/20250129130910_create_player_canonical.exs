defmodule DraftGuru.Repo.Migrations.CreatePlayerCanonical do
  use Ecto.Migration

  def change do
    create table(:player_canonical) do
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :suffix, :string
      add :draft_year, :integer

      timestamps(type: :utc_datetime)
    end
  end
end

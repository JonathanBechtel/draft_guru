defmodule DraftGuru.Repo.Migrations.CreatePlayerCanonical do
  use Ecto.Migration

  def change do
    create table(:player_canonical) do
      add :first_name, :string, null: false
      add :middle_name, :string
      add :last_name, :string, null: false
      add :suffix, :string
      add :draft_year, :integer

      timestamps(utc: :datetime)
    end
  end
end

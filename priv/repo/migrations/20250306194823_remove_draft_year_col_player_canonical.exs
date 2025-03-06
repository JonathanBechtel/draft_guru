defmodule DraftGuru.Repo.Migrations.RemoveDraftYearColPlayerCanonical do
  use Ecto.Migration

  def up do
    alter table(:player_canonical) do
      remove :draft_year
    end
  end

  def down do
    alter table(:player_canonical) do
      add :draft_year, :integer
    end
  end
end

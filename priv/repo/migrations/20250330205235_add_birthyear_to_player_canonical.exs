# priv/repo/migrations/YYYYMMDDHHMMSS_add_birth_year_to_player_canonical.exs
defmodule DraftGuru.Repo.Migrations.AddBirthYearToPlayerCanonical do
  use Ecto.Migration

  def change do
    alter table(:player_canonical) do
      # Add birth_year, allowing NULL for existing records
      add :birth_date, :date
    end
  end
end

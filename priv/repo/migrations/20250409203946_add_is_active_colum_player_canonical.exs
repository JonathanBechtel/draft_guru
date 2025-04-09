defmodule DraftGuru.Repo.Migrations.AddIsActiveColumPlayerCanonical do
  use Ecto.Migration

  def change do
    alter table(:player_canonical) do
      add :is_active, :boolean, default: false
    end
  end
end

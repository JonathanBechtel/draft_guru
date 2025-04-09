defmodule DraftGuru.Repo.Migrations.RemoveIsActiveFromPlayerCanonical do
  use Ecto.Migration

  def change do
    alter table(:player_canonical) do
      remove :is_active
    end
  end
end

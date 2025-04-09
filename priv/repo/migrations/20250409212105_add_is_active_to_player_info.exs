defmodule DraftGuru.Repo.Migrations.AddIsActiveToPlayerInfo do
  use Ecto.Migration

  def change do
    alter table(:player_info) do
      add :is_active, :boolean, default: false
    end
  end
end

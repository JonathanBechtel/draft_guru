defmodule DraftGuru.Repo.Migrations.AddPlayedInNbaToPlayerInfo do
  use Ecto.Migration

  def change do
    alter table(:player_info) do
      add :played_in_nba, :boolean, default: false, null: false
    end
  end
end

defmodule DraftGuru.Repo.Migrations.AddHometownStateToPlayerInfo do
  use Ecto.Migration

  def change do
    alter table(:player_info) do
      add :hometown, :string
      add :state, :string
      add :country, :string
    end
  end
end

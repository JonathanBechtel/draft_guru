defmodule DraftGuru.Repo.Migrations.AddBirthDateToPlayerInfo do
  use Ecto.Migration

  def change do
    alter table(:player_info) do
      add(:birth_date, :date)
    end
  end
end

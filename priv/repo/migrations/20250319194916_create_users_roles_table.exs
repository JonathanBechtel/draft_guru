defmodule DraftGuru.Repo.Migrations.CreateUsersRolesTable do
  use Ecto.Migration

  def change do
    create table(:users_roles) do
      add :role, :string, null: false

      timestamps(utc: :datetime)
    end
  end
end

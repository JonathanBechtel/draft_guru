defmodule DraftGuru.Repo.Migrations.CreateUserRolesTable do
  use Ecto.Migration

  def change do
    create table(:user_roles) do
      add :role, :string, null: false

      timestamps(utc: :datetime)
    end

    create unique_index(:user_roles, [:role])
  end
end

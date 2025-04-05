defmodule DraftGuru.Repo.Migrations.AddForeignKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_role_id, references(:user_roles, on_delete: :nothing), null: false
    end
  end
end

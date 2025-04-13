defmodule DraftGuru.Repo.Migrations.AddForeignKeyToUsers do
  use Ecto.Migration

  def change do
    # Check if the column already exists before trying to add it
    unless column_exists?(:users, :user_role_id) do
      alter table(:users) do
        add :user_role_id, references(:user_roles, on_delete: :nothing), null: false
      end
    end
  end

  # Helper function to check if column exists
  defp column_exists?(table, column) do
    query = """
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = '#{table}'
    AND column_name = '#{column}'
    """

    case repo().query(query) do
      {:ok, %{num_rows: 1}} -> true
      _ -> false
    end
  end
end

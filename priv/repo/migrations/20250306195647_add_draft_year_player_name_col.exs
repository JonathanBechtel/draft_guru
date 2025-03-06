defmodule DraftGuru.Repo.Migrations.AddDraftYearPlayerNameCol do
  use Ecto.Migration

  def change do
    alter table(:player_combine_stats) do
      add :draft_year, :integer
      add :player_name, :string
    end
  end
end

# lib/draft_guru/release.ex
defmodule DraftGuru.Release do
  @app :draft_guru
  alias DraftGuru.Repo
  alias DraftGuru.Accounts.{UserRoles, Users}

  # ── public entry points ────────────────────────────────────────────────
  def migrate, do: with_app(&run_migrations/0)
  def seed,    do: with_app(&run_seeds/0)

  # ── private helpers ────────────────────────────────────────────────────
  defp with_app(fun) do
    # 1. Read the application’s config without starting it
    Application.load(@app)

    # 2. Start only Ecto and the packages it depends on
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    # (ecto_sql pulls in :logger, :crypto, :ssl, :postgrex, etc.)

    # 3. Start the repo manually
    {:ok, _pid} = DraftGuru.Repo.start_link()

    # 4. Finally run the work that the task was called for
    fun.()
  end

  defp run_migrations do
    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp run_seeds do
    seed_roles()
    seed_admin()
    seed_players()
  end

  # -- seeds ---------------------------------------------------------------
  defp seed_roles do
    now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()

    roles = ~w(admin contributor user)

    Repo.insert_all(
      UserRoles,
      Enum.map(roles, &%{role: &1, inserted_at: now, updated_at: now}),
      on_conflict: :nothing,
      conflict_target: :role
    )
  end


  defp seed_admin do
    email    = System.get_env("ADMIN_EMAIL")
    password = System.get_env("ADMIN_PASSWORD")

    %{id: role_id} = Repo.get_by!(UserRoles, role: "admin")

    Users.registration_changeset(
      %Users{user_role_id: role_id},
      %{email: email, password: password}
    )
    |> Repo.insert(on_conflict: :nothing, conflict_target: :email)
  end

  defp seed_players do
    data_dir =
      Application.app_dir(@app, "priv/data_files")   # <‑‑ copy CSVs here in Dockerfile

    Path.wildcard(Path.join(data_dir, "*.csv"))
    |> Enum.each(&DraftGuru.DraftCombineStatsSeed.seed_data/1)
  end
end

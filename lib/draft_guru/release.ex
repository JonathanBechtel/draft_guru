# lib/draft_guru/release.ex
defmodule DraftGuru.Release do
  @app :draft_guru
  alias DraftGuru.Repo
  alias DraftGuru.Accounts.{UserRoles, Users}

  # ── public entry points ────────────────────────────────────────────────
  def migrate, do: with_app(&run_migrations/0)
  def seed, do: with_app(&run_seeds/0)
  def create_admin, do: with_app(&seed_admin/0)

  # ── private helpers ────────────────────────────────────────────────────
  defp with_app(fun) do

    # Load the application's compile-time configuration
    Application.load(@app)

    # Start Ecto and its dependencies
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    {:ok, _pid} = Repo.start_link()

    # Finally, run the function passed to with_app
    fun.()
  end

  defp run_migrations do
    # This can now be simplified since the Repo is started and configured.
    Ecto.Migrator.run(Repo, :up, all: true)
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
    # This part is now correct because `with_app` has loaded the config.
    email = System.get_env("ADMIN_EMAIL")
    password = System.get_env("ADMIN_PASSWORD")

    if is_nil(email) || is_nil(password) do
      IO.puts("❌ ADMIN_EMAIL and ADMIN_PASSWORD environment variables must be set")
      IO.puts("   Hint: Check if config/runtime.exs is loading them correctly.")
      IO.puts("   Current values: email=#{inspect(email)}, password=#{inspect(password)}")
      {:error, :missing_env_vars}
    else
      # Ensure roles are seeded first, in case this is run standalone.
      seed_roles()

      case Repo.get_by(UserRoles, role: "admin") do
        nil ->
          IO.puts("❌ 'admin' role not found in database. Please run seeds first.")
          {:error, :admin_role_not_found}

        %{id: role_id} ->
          changeset =
            Users.registration_changeset(%Users{user_role_id: role_id}, %{
              email: email,
              password: password
            })

          case Repo.insert(changeset, on_conflict: :nothing, conflict_target: :email) do
            {:ok, user} ->
              IO.puts("✅ Admin user created successfully: #{user.email}")
              {:ok, user}

            {:error, changeset} ->
              IO.puts("❌ Failed to create admin user:")
              IO.inspect(changeset.errors, label: "Validation errors")
              {:error, changeset}
          end
      end
    end
  end

  defp seed_players do
    data_dir =
      Application.app_dir(@app, "priv/data_files")

    Path.wildcard(Path.join(data_dir, "*.csv"))
    |> Enum.each(&DraftGuru.DraftCombineStatsSeed.seed_data/1)
  end
end

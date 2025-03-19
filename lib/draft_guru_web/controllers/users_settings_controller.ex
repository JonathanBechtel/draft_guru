defmodule DraftGuruWeb.UsersSettingsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Accounts
  alias DraftGuruWeb.UsersAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "users" => users_params} = params
    users = conn.assigns.current_users

    case Accounts.apply_users_email(users, password, users_params) do
      {:ok, applied_users} ->
        Accounts.deliver_users_update_email_instructions(
          applied_users,
          users.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "users" => users_params} = params
    users = conn.assigns.current_users

    case Accounts.update_users_password(users, password, users_params) do
      {:ok, users} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:users_return_to, ~p"/users/settings")
        |> UsersAuth.log_in_users(users)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_users_email(conn.assigns.current_users, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    users = conn.assigns.current_users

    conn
    |> assign(:email_changeset, Accounts.change_users_email(users))
    |> assign(:password_changeset, Accounts.change_users_password(users))
  end
end

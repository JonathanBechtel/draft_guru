defmodule DraftGuruWeb.UsersResetPasswordController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Accounts

  plug :get_users_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"users" => %{"email" => email}}) do
    if users = Accounts.get_users_by_email(email) do
      Accounts.deliver_users_reset_password_instructions(
        users,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, _params) do
    render(conn, :edit, changeset: Accounts.change_users_password(conn.assigns.users))
  end

  # Do not log in the users after reset password to avoid a
  # leaked token giving the users access to the account.
  def update(conn, %{"users" => users_params}) do
    case Accounts.reset_users_password(conn.assigns.users, users_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: ~p"/users/log_in")

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp get_users_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if users = Accounts.get_users_by_reset_password_token(token) do
      conn |> assign(:users, users) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end

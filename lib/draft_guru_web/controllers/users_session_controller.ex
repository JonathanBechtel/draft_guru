defmodule DraftGuruWeb.UsersSessionController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Accounts
  alias DraftGuruWeb.UsersAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"users" => users_params}) do
    %{"email" => email, "password" => password} = users_params

    if users = Accounts.get_users_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UsersAuth.log_in_users(users, users_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UsersAuth.log_out_users()
  end
end

defmodule DraftGuruWeb.UsersRegistrationController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Accounts
  alias DraftGuru.Accounts.Users
  alias DraftGuruWeb.UsersAuth

  def new(conn, _params) do
    changeset = Accounts.change_users_registration(%Users{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"users" => users_params}) do
    case Accounts.register_users(users_params) do
      {:ok, users} ->
        {:ok, _} =
          Accounts.deliver_users_confirmation_instructions(
            users,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Users created successfully.")
        |> UsersAuth.log_in_users(users)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end

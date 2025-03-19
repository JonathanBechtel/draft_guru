defmodule DraftGuruWeb.UsersConfirmationControllerTest do
  use DraftGuruWeb.ConnCase, async: true

  alias DraftGuru.Accounts
  alias DraftGuru.Repo
  import DraftGuru.AccountsFixtures

  setup do
    %{users: users_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/users/confirm")
      response = html_response(conn, 200)
      assert response =~ "Resend confirmation instructions"
    end
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, users: users} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "users" => %{"email" => users.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.UsersToken, users_id: users.id).context == "confirm"
    end

    test "does not send confirmation token if Users is confirmed", %{conn: conn, users: users} do
      Repo.update!(Accounts.Users.confirm_changeset(users))

      conn =
        post(conn, ~p"/users/confirm", %{
          "users" => %{"email" => users.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.UsersToken, users_id: users.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "users" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.UsersToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      token_path = ~p"/users/confirm/some-token"
      conn = get(conn, token_path)
      response = html_response(conn, 200)
      assert response =~ "Confirm account"

      assert response =~ "action=\"#{token_path}\""
    end
  end

  describe "POST /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, users: users} do
      token =
        extract_users_token(fn url ->
          Accounts.deliver_users_confirmation_instructions(users, url)
        end)

      conn = post(conn, ~p"/users/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Users confirmed successfully"

      assert Accounts.get_users!(users.id).confirmed_at
      refute get_session(conn, :users_token)
      assert Repo.all(Accounts.UsersToken) == []

      # When not logged in
      conn = post(conn, ~p"/users/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Users confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_users(users)
        |> post(~p"/users/confirm/#{token}")

      assert redirected_to(conn) == ~p"/"
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, users: users} do
      conn = post(conn, ~p"/users/confirm/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Users confirmation link is invalid or it has expired"

      refute Accounts.get_users!(users.id).confirmed_at
    end
  end
end

defmodule DraftGuruWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = conn.assigns[:current_user] || conn.assigns[:current_users]

    IO.inspect(current_user, label: "current user")
    if current_user && current_user.user_role_id == 1 do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to view this page.")
      |> redirect(to: "/") # or some other route
      |> halt()
    end
  end
end

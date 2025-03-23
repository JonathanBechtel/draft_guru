defmodule DraftGuruWeb.Plugs.BasicAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    username = Keyword.fetch!(opts, :username)
    password = Keyword.fetch!(opts, :password)

    case Plug.BasicAuth.basic_auth(conn, username: username, password: password) do
      :ok -> conn
      :error -> conn
      |> put_resp_header("www-authenticate", "Basic realm=\"Restricted Area\"")
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end
end

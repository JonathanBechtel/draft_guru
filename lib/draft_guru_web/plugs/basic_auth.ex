defmodule DraftGuruWeb.Plugs.BasicAuth do
  @spec init(any()) :: any()
  def init(opts), do: opts

  def call(conn, _opts) do
    username = Application.get_env(:draft_guru, :basic_auth)[:username]
    password = Application.get_env(:draft_guru, :basic_auth)[:password]

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end

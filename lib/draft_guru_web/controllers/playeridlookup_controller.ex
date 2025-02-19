defmodule DraftGuruWeb.PlayerIdLookupController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerIDLookups


  def index(conn, params) do

    lookups = PlayerIDLookups.list_player_id_lookups(params)

    render(conn, :index,
          lookups: lookups,
          search: Map.get(params, "idlookup", ""))
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id} = params) do
    IO.inspect(params, label: "params for player id lookup")
    player_id_lookup = PlayerIDLookups.get_lookup!(id)

    render(conn, :show,
           player_id_lookup: player_id_lookup)
  end
end

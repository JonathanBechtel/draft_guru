defmodule DraftGuruWeb.PlayerIdLookupController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerIDLookups


  def index(conn, params) do
    %{
      records: lookups,
      total_pages: total_pages
    } = PlayerIDLookups.list_player_id_lookups(params)

    render(conn, :index,
          lookups: lookups,
          total_pages: total_pages,
          page: Map.get(params, "page", "1"),
          sort_field: Map.get(params, "sort_field", "id"),
          sort_direction: Map.get(params, "sort_direction", "asc"),
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

defmodule DraftGuruWeb.PlayerCombineStatsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerCombineStats

  def index(conn, params) do
    %{
      records: players,
      total_pages: total_pages
    } = PlayerCombineStats.list_players_combine_stats(params)

    IO.inspect(players, label: "players after being selected")

    render(conn,
          :index,
          players: players,
          total_pages: total_pages,
          page: Map.get(params, "page", "1"),
          sort_field: Map.get(params, "sort_field", "id"),
          sort_direction: Map.get(params, "sort_direction", "asc"),
          search: Map.get(params, "player_name", ""))
  end

  def show(conn, %{"id" => id} = _params) do
    player = PlayerCombineStats.get_player!(id)

    render(conn,
          :show,
          player: player
    )
  end

end

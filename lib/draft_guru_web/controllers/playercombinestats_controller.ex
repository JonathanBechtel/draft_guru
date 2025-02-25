defmodule DraftGuruWeb.PlayerCombineStatsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerCombineStats
  alias DraftGuru.Players.PlayerCombineStat

  def index(conn, params) do
    players = PlayerCombineStats.list_players_combine_stats(params)
    total_pages = PlayerCombineStats.get_total_pages(PlayerCombineStat)

    render(conn,
          :index,
          players: players,
          total_pages: total_pages,
          page: Map.get(params, "page", "1"),
          search: Map.get(params, "player_slug", ""))
  end

end

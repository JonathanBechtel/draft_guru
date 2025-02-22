defmodule DraftGuruWeb.PlayerCombineStatsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerCombineStats

  def index(conn, params) do
    players = PlayerCombineStats.list_players_combine_stats(params)

    render(conn,
          :index,
          players: players,
          search: Map.get(params, "player_combine_stats_search", ""))
  end

end

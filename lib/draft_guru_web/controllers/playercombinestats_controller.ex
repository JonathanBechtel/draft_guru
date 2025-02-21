defmodule DraftGuruWeb.PlayerCombineStatsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerCombineStats

  def index(conn, _params) do
    players = PlayerCombineStats.list_players_combine_stats()

    render(conn,
          :index,
          players: players)
  end

end

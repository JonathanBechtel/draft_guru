defmodule DraftGuru.PlayerIdLookupController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerIDLookups
  alias DraftGuru.PlayerIDLookups.PlayerIDLookup


  def index(conn, params) do

    lookups = PlayerIDLookups.list_player_id_lookups()
    render(conn, :index,
          lookups: lookups)
  end

  def show(conn, {"id" => id} = params) do
    player_id_lookup = PlayerIDLookup.get
  end
end

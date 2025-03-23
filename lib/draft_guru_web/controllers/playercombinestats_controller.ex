defmodule DraftGuruWeb.PlayerCombineStatsController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Players.PlayerCombineStat
  alias DraftGuru.PlayerCombineStats

  def index(conn, params) do
    %{
      records: players,
      total_pages: total_pages
    } = PlayerCombineStats.list_players_combine_stats(params)

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
    player = PlayerCombineStats.get_player_combine_stats_w_full_name!(id)

    render(conn,
          :show,
          player: player
    )
  end

  def edit(conn, %{"id" => id} = _params) do
    player = PlayerCombineStats.get_player_combine_stats!(id)

    changeset = PlayerCombineStats.change_player_combine_stats(player)

    render(conn,
          :edit,
           player: player,
           changeset: changeset)
  end

  def update(conn, %{"id" => id, "player_combine_stat" => player_params}) do
    player = PlayerCombineStats.get_player_combine_stats!(id)

    case PlayerCombineStats.update_player_combine_stats(player, player_params) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Player updated successfully.")
        |> redirect(to: ~p"/models/player_combine_stats/#{player}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, player: player, changeset: changeset)
    end
  end

  def create(conn, %{"player_combine_stat" => player_params}) do
    case PlayerCombineStats.create_player_combine_stats(player_params) do
      {:ok, _result} ->
        conn
        |> put_flash(:info, "Sucessfully created player.")
        |> redirect(to: ~p"/models/player_combine_stats")

      {:error, failed_operation, failed_value, _changes_so_far} ->
        # is there a better way to handle this?
        conn
        |> put_flash(:error, "Failed to successfully create the record.  Operation: #{failed_operation}, value: #{failed_value}")
        |> render(conn, :new)
    end
  end

  def new(conn, _params) do
    changeset = PlayerCombineStats.change_player_combine_stats(%PlayerCombineStat{})
    render(conn, :new, changeset: changeset)
  end

  def delete(conn, %{"id" => id}) do
    player = PlayerCombineStats.get_player_combine_stats!(id)
    {:ok, _player} = PlayerCombineStats.delete_player_combine_stats(player)

    conn
    |> put_flash(:info, "Player deleted successfully.")
    |> redirect(to: ~p"/models/player_combine_stats")
  end

end

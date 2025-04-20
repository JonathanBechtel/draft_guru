# lib/draft_guru_web/controllers/player_info_controller.ex
defmodule DraftGuruWeb.PlayerInfoController do
  use DraftGuruWeb, :controller

  alias DraftGuru.PlayerInfos
  alias DraftGuru.Players.PlayerInfo

  def index(conn, params) do
    %{
      records: player_infos,
      total_pages: total_pages
    } = PlayerInfos.list_player_infos(params)

    render(conn, :index,
      player_infos: player_infos,
      total_pages: total_pages,
      page: Map.get(params, "page", "1"),
      # Add sorting/searching params if implemented
      sort_field: Map.get(params, "sort_field", "id"),
      sort_direction: Map.get(params, "sort_direction", "asc"),
      search: Map.get(params, "search", "")
    )
  end

  def new(conn, _params) do
    changeset = PlayerInfos.change_player_info(%PlayerInfo{})
    players_for_select = PlayerInfos.list_players_for_select()
    render(conn, :new, changeset: changeset, players_for_select: players_for_select)
  end

  def create(conn, %{"player_info" => player_info_params}) do
    case PlayerInfos.create_player_info(player_info_params) do
      {:ok, player_info} ->
        conn
        |> put_flash(:info, "Player info created successfully.")
        |> redirect(to: ~p"/models/player_info/#{player_info}")

      {:error, %Ecto.Changeset{} = changeset} ->
        players_for_select = PlayerInfos.list_players_for_select()
        render(conn, :new, changeset: changeset, players_for_select: players_for_select)
    end
  end

  def show(conn, %{"id" => id}) do
    player_info = PlayerInfos.get_player_info!(id)
    render(conn, :show, player_info: player_info)
  end

  def edit(conn, %{"id" => id}) do
    player_info = PlayerInfos.get_player_info!(id)
    changeset = PlayerInfos.change_player_info(player_info)
    players_for_select = PlayerInfos.list_players_for_select()
    render(conn, :edit,
      player_info: player_info,
      changeset: changeset,
      players_for_select: players_for_select
    )
  end

  def update(conn, %{"id" => id, "player_info" => player_info_params}) do
    player_info = PlayerInfos.get_player_info!(id)

    case PlayerInfos.update_player_info(player_info, player_info_params) do
      {:ok, player_info} ->
        conn
        |> put_flash(:info, "Player info updated successfully.")
        |> redirect(to: ~p"/models/player_info/#{player_info}")

      {:error, %Ecto.Changeset{} = changeset} ->
        players_for_select = PlayerInfos.list_players_for_select()
        render(conn, :edit,
          player_info: player_info,
          changeset: changeset,
          players_for_select: players_for_select
        )
    end
  end

  def bulk_update(conn, %{"bulk_update" => %{"players" => players}}) do
    results = PlayerInfos.bulk_update_active_status(players)
    success_count = results |> Enum.filter(fn {status, _} -> status == :ok end) |> Enum.count()

    conn
    |> put_flash(:info, "Successfully updated #{success_count} player(s) active status.")
    |> redirect(to: ~p"/models/player_info")
  end

  def delete(conn, %{"id" => id}) do
    player_info = PlayerInfos.get_player_info!(id)
    {:ok, _player_info} = PlayerInfos.delete_player_info(player_info)

    conn
    |> put_flash(:info, "Player info deleted successfully.")
    |> redirect(to: ~p"/models/player_info")
  end
end

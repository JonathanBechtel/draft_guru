defmodule DraftGuruWeb.PlayerController do
  use DraftGuruWeb, :controller

  alias DraftGuru.Players
  alias DraftGuru.Players.Player

  def index(conn, params) do
    players = Players.list_player_canonical(params)

    render(conn, :index,
      player_canonical: players,
      search: Map.get(params, "name", ""),
      page: Map.get(params, "page", "1"),
      sort_field: Map.get(params, "sort_field", "id"),
      sort_direction: Map.get(params, "sort_direction", "asc")
    )
  end

  def new(conn, _params) do
    changeset = Players.change_player(%Player{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"player" => player_params}) do
    case Players.create_player(player_params) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Player created successfully.")
        |> redirect(to: ~p"/player_canonical/#{player}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    render(conn, :show, player: player)
  end

  def edit(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    changeset = Players.change_player(player)
    render(conn, :edit, player: player, changeset: changeset)
  end

  def update(conn, %{"id" => id, "player" => player_params}) do
    player = Players.get_player!(id)

    case Players.update_player(player, player_params) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Player updated successfully.")
        |> redirect(to: ~p"/player_canonical/#{player}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, player: player, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    {:ok, _player} = Players.delete_player(player)

    conn
    |> put_flash(:info, "Player deleted successfully.")
    |> redirect(to: ~p"/player_canonical")
  end
end

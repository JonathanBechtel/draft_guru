defmodule DraftGuruWeb.PlayerControllerTest do
  use DraftGuruWeb.ConnCase

  import DraftGuru.PlayersFixtures

  @create_attrs %{id: 42, suffix: "some suffix", first_name: "some first_name", middle_name: "some middle_name", last_name: "some last_name", draft_year: 42}
  @update_attrs %{id: 43, suffix: "some updated suffix", first_name: "some updated first_name", middle_name: "some updated middle_name", last_name: "some updated last_name", draft_year: 43}
  @invalid_attrs %{id: nil, suffix: nil, first_name: nil, middle_name: nil, last_name: nil, draft_year: nil}

  describe "index" do
    test "lists all player_canonical", %{conn: conn} do
      conn = get(conn, ~p"/player_canonical")
      assert html_response(conn, 200) =~ "Listing Player canonical"
    end
  end

  describe "new player" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/player_canonical/new")
      assert html_response(conn, 200) =~ "New Player"
    end
  end

  describe "create player" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/player_canonical", player: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/player_canonical/#{id}"

      conn = get(conn, ~p"/player_canonical/#{id}")
      assert html_response(conn, 200) =~ "Player #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/player_canonical", player: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Player"
    end
  end

  describe "edit player" do
    setup [:create_player]

    test "renders form for editing chosen player", %{conn: conn, player: player} do
      conn = get(conn, ~p"/player_canonical/#{player}/edit")
      assert html_response(conn, 200) =~ "Edit Player"
    end
  end

  describe "update player" do
    setup [:create_player]

    test "redirects when data is valid", %{conn: conn, player: player} do
      conn = put(conn, ~p"/player_canonical/#{player}", player: @update_attrs)
      assert redirected_to(conn) == ~p"/player_canonical/#{player}"

      conn = get(conn, ~p"/player_canonical/#{player}")
      assert html_response(conn, 200) =~ "some updated suffix"
    end

    test "renders errors when data is invalid", %{conn: conn, player: player} do
      conn = put(conn, ~p"/player_canonical/#{player}", player: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Player"
    end
  end

  describe "delete player" do
    setup [:create_player]

    test "deletes chosen player", %{conn: conn, player: player} do
      conn = delete(conn, ~p"/player_canonical/#{player}")
      assert redirected_to(conn) == ~p"/player_canonical"

      assert_error_sent 404, fn ->
        get(conn, ~p"/player_canonical/#{player}")
      end
    end
  end

  defp create_player(_) do
    player = player_fixture()
    %{player: player}
  end
end

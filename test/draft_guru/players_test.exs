defmodule DraftGuru.PlayersTest do
  use DraftGuru.DataCase

  alias DraftGuru.Players

  describe "player_canonical" do
    alias DraftGuru.Players.Player

    import DraftGuru.PlayersFixtures

    @invalid_attrs %{id: nil, suffix: nil, first_name: nil, middle_name: nil, last_name: nil, draft_year: nil}

    test "list_player_canonical/0 returns all player_canonical" do
      player = player_fixture()
      assert Players.list_player_canonical() == [player]
    end

    test "get_player!/1 returns the player with given id" do
      player = player_fixture()
      assert Players.get_player!(player.id) == player
    end

    test "create_player/1 with valid data creates a player" do
      valid_attrs = %{id: 42, suffix: "some suffix", first_name: "some first_name", middle_name: "some middle_name", last_name: "some last_name", draft_year: 42}

      assert {:ok, %Player{} = player} = Players.create_player(valid_attrs)
      assert player.id == 42
      assert player.suffix == "some suffix"
      assert player.first_name == "some first_name"
      assert player.middle_name == "some middle_name"
      assert player.last_name == "some last_name"
      assert player.draft_year == 42
    end

    test "create_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Players.create_player(@invalid_attrs)
    end

    test "update_player/2 with valid data updates the player" do
      player = player_fixture()
      update_attrs = %{id: 43, suffix: "some updated suffix", first_name: "some updated first_name", middle_name: "some updated middle_name", last_name: "some updated last_name", draft_year: 43}

      assert {:ok, %Player{} = player} = Players.update_player(player, update_attrs)
      assert player.id == 43
      assert player.suffix == "some updated suffix"
      assert player.first_name == "some updated first_name"
      assert player.middle_name == "some updated middle_name"
      assert player.last_name == "some updated last_name"
      assert player.draft_year == 43
    end

    test "update_player/2 with invalid data returns error changeset" do
      player = player_fixture()
      assert {:error, %Ecto.Changeset{}} = Players.update_player(player, @invalid_attrs)
      assert player == Players.get_player!(player.id)
    end

    test "delete_player/1 deletes the player" do
      player = player_fixture()
      assert {:ok, %Player{}} = Players.delete_player(player)
      assert_raise Ecto.NoResultsError, fn -> Players.get_player!(player.id) end
    end

    test "change_player/1 returns a player changeset" do
      player = player_fixture()
      assert %Ecto.Changeset{} = Players.change_player(player)
    end
  end
end

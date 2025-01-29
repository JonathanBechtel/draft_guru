defmodule DraftGuru.PlayersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DraftGuru.Players` context.
  """

  @doc """
  Generate a player.
  """
  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> Enum.into(%{
        draft_year: 42,
        first_name: "some first_name",
        id: 42,
        last_name: "some last_name",
        middle_name: "some middle_name",
        suffix: "some suffix"
      })
      |> DraftGuru.Players.create_player()

    player
  end
end

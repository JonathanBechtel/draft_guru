defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStat

  def list_players_combine_stats, do: Repo.all(PlayerCombineStat)

  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStat, id)

  def get_player_combine_stats_by_player_id!(player_id), do: Repo.get_by!(PlayerCombineStat, player_id)

  def create_player_combine_stats(attrs \\ %{}) do
    %PlayerCombineStat{}
    |> PlayerCombineStat.changeset(attrs)
    |> Repo.insert()
  end
end

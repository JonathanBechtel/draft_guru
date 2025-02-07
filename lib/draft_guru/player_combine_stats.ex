defmodule DraftGuru.PlayerCombineStat do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStats


  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStats, id)

  def get_player_combine_stats_by_player_id!(player_id), do: Repo.get_by!(PlayerCombineStats, player_id)

  def create_player_combine_stats(attrs \\ %{}) do
    %PlayerCombineStats{}
    |> PlayerCombineStats.changeset(attrs)
    |> Repo.insert()
  end
end

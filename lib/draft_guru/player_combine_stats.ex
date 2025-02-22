defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStat

  def list_players_combine_stats(params) do

    player_slug = Map.get(params, "player_slug")

    query = PlayerCombineStat

    query = maybe_apply_search(query, player_slug)

    Repo.all(query)

  end

  defp maybe_apply_search(query, ""), do: query
  defp maybe_apply_search(query, nil), do: query
  defp maybe_apply_search(query, player_slug) do
      from(p in query,
          where:
            ilike(p.player_slug, ^"%#{idlookup}%"))
  end

  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStat, id)

  def get_player_combine_stats_by_player_id!(player_id), do: Repo.get_by!(PlayerCombineStat, player_id)

  def create_player_combine_stats(attrs \\ %{}) do
    %PlayerCombineStat{}
    |> PlayerCombineStat.changeset(attrs)
    |> Repo.insert()
  end
end

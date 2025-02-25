defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStat

  def list_players_combine_stats(params) do

    player_slug = Map.get(params, "player_combine_stats_search")

    query = PlayerCombineStat

    query = maybe_apply_search(query, player_slug)

    _page = to_integer_with_default(Map.get(params, "page"), 1)

    Repo.all(query)

  end

  defp maybe_apply_search(query, ""), do: query
  defp maybe_apply_search(query, nil), do: query
  defp maybe_apply_search(query, player_slug) do
      from(p in query,
          where:
            ilike(p.player_slug, ^"%#{player_slug}%"))
  end

  defp to_integer_with_default(nil, default), do: default
  defp to_integer_with_default(str, default) do
    case Integer.parse(to_string(str)) do
      {int, _} -> int
      :error   -> default
    end
  end

  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStat, id)

  def get_player_combine_stats_by_player_id!(player_id), do: Repo.get_by!(PlayerCombineStat, player_id)

  def create_player_combine_stats(attrs \\ %{}) do
    %PlayerCombineStat{}
    |> PlayerCombineStat.changeset(attrs)
    |> Repo.insert()
  end
end

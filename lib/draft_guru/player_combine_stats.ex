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

    query = apply_sorting(query, params)

    page = to_integer_with_default(Map.get(params, "page"), 1)
    page_size = 100
    offset = (page - 1) * page_size

    query =
      query
      |> limit(^page_size)
      |> offset(^offset)

    Repo.all(query)

  end

  defp apply_sorting(query, params) do
    allowed_fields = ["id"]
    sort_field = Map.get(params, "sort_field", "id")
    sort_direction = Map.get(params, "sort_direction", "asc")

    sort_field =
      if sort_field in allowed_fields do
        sort_field
      else
        "id"
      end

    # convert sort_field to atom to use w/ ecto query
    sort_dir_atom =
      case sort_direction do
        "desc" -> :desc
        _ -> :asc
      end

    sort_field_atom = String.to_existing_atom(sort_field)

    from p in query,
      order_by: [{^sort_dir_atom, field(p, ^sort_field_atom)}]

  end

  def get_total_pages(table_struct) do
    total_count = Repo.one(from p in table_struct, select: count(p.id))

    Float.ceil(total_count / 100)
    |> trunc()
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

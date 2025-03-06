defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStat

  def get_player_combine_stats_w_full_name!(id) do
    query = PlayerCombineStat

    query = from(pcs in query,
    join: p in assoc(pcs, :player_canonical),
    preload: [player_canonical: p])

    Repo.get!(query, id)

  end

  def list_players_combine_stats(params) do

    player_slug = Map.get(params, "player_slug")

    query = PlayerCombineStat

    query = from(pcs in query,
      join: p in assoc(pcs, :player_canonical),
      preload: [player_canonical: p])

    query = maybe_apply_search(query, player_slug)

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, params)

    page = to_integer_with_default(Map.get(params, "page"), 1)
    page_size = 100
    offset = (page - 1) * page_size

    total_pages = ceil(record_count / page_size)

    query =
      query
      |> limit(^page_size)
      |> offset(^offset)

    records = Repo.all(query)

    %{
      records: records,
      total_pages: total_pages
    }

  end

  defp apply_sorting(query, params) do
    allowed_fields = ["id", "position", "player_slug", "lane_agility_time", "shuttle_run",
                      "three_quarter_sprint", "standing_vertical_leap", "max_vertical_leap",
                      "max_bench_press_repetitions", "height_w_shoes", "height_wo_shoes", "body_fat_pct",
                      "hand_length", "hand_length_inches", "hand_width", "standing_reach", "standing_reach_inches",
                      "weight_lbs", "wingspan", "wingspan_inches", "height_w_shoes_inches", "height_wo_shoes_inches",
                      "player_id", "player_name", "draft_year"]
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
  defp maybe_apply_search(query, player_name) do
      from([pcs, p] in query,
          where:
            ilike(fragment("? || ' ' || ?", p.first_name, p.last_name), ^"%#{player_name}%"))
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

  def change_player_combine_stats(%PlayerCombineStat{} = player_combine_stat, attrs \\ %{}) do

    PlayerCombineStat.changeset(player_combine_stat, attrs)
  end

  def update_player_combine_stats(%PlayerCombineStat{} = player, attrs) do
    player
    |> PlayerCombineStat.changeset(attrs)
    |> Repo.update()
  end

  def delete_player_combine_stats(%PlayerCombineStat{} = player) do
    Repo.delete(player)
  end

end

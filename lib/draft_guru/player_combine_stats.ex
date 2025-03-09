defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
 import Ecto.Query, warn: false
 import DraftGuru.DataCollection.Utilities, only: [split_name_into_parts: 1,
                                                    sanitize: 1,
                                                    clean_map_value: 1]

  alias DraftGuru.Repo

  alias DraftGuru.Players.PlayerCombineStat
  alias DraftGuru.Players.Player
  alias DraftGuru.Players.PlayerIdLookup

  @spec get_player_combine_stats_w_full_name!(any()) :: any()
  def get_player_combine_stats_w_full_name!(id) do
    query = PlayerCombineStat

    query = from(cs in query,
    join: p in assoc(cs, :player_canonical),
    preload: [player_canonical: p])

    Repo.get!(query, id)

  end

  def list_players_combine_stats(params) do

    player_slug = Map.get(params, "player_slug")

    query = PlayerCombineStat

    query = maybe_apply_search(query, player_slug)

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, params)

    age = to_integer_with_default(Map.get(params, "age"), 1)
    page_size = 100
    offset = (age - 1) * page_size

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

  def apply_sorting(query, params) do
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

  def maybe_apply_search(query, ""), do: query
  def maybe_apply_search(query, nil), do: query
  def maybe_apply_search(query, player_name) do
      from(p in query,
          where:
            ilike(p.player_name, ^"%#{player_name}%"))
  end

  def to_integer_with_default(nil, default), do: default
  def to_integer_with_default(str, default) do
    case Integer.parse(to_string(str)) do
      {int, _} -> int
      :error   -> default
    end
  end
  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStat, id)

  def get_player_combine_stats_by_player_id!(layer_id), do: Repo.get_by!(PlayerCombineStat, layer_id)

  def create_player_combine_stats(attrs \\ %{}) do

    keys_to_format = [
      "height_w_shoes",
      "height_wo_shoes",
      "standing_reach",
      "wingspan",
      "hand_length",
      "hand_width"
     ]

    # stri white sace and extra unctuation from layer name
    combine_stats_attrs = Map.put(attrs, "player_name", sanitize(attrs["player_name"]))

    # convert measurements to inches
    combine_stats_attrs = Enum.reduce(keys_to_format, combine_stats_attrs, fn key, acc ->
      value = Map.get(acc, key)
      Map.put(acc, "#{key}_inches", clean_map_value(value))
    end)

    # get the attributes for the layer_canonical table
    canonical_attrs =
      %{}
      |> Map.merge(split_name_into_parts(combine_stats_attrs["player_name"]))

    player_slug = "#{canonical_attrs[:first_name]}_#{canonical_attrs[:middle_name]}_#{canonical_attrs[:last_name]}_#{canonical_attrs[:suffix]}_#{attrs["draft_year"]}"
    combine_stats_attrs = Map.put(combine_stats_attrs, "player_slug", player_slug)

    player_id_attrs =
      %{}
      |> Map.put("data_source_id", player_slug)
      |> Map.put("data_source", "nba.com/stats/draft")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:player_canonical, Player.changeset(%Player{}, canonical_attrs))
    |> Ecto.Multi.insert(:player_id_lookup, fn %{player_canonical: player_canonical} ->
      PlayerIdLookup.changeset(%PlayerIdLookup{},
        Map.put(player_id_attrs, "player_id", player_canonical.id))
    end)
    |> Ecto.Multi.insert(:player_combine_stats, fn %{player_canonical: player_canonical} ->
      PlayerCombineStat.changeset(%PlayerCombineStat{},
        Map.put(combine_stats_attrs, "player_id", player_canonical.id))
    end)
    |> Repo.transaction()

  end

  def change_player_combine_stats(%PlayerCombineStat{} = player_combine_stat, attrs \\ %{}) do

    PlayerCombineStat.changeset(player_combine_stat, attrs)
  end

  def update_player_combine_stats(%PlayerCombineStat{} = player, attrs) do
    player
    |> PlayerCombineStat.changeset(attrs)
    |> Repo.update()
  end

  def delete_player_combine_stats(%PlayerCombineStat{} = layer) do
    Repo.delete(layer)
  end

end

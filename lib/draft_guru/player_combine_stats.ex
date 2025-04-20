defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStat table
  """
 import Ecto.Query, warn: false
 import DraftGuru.DataCollection.Utilities, only: [split_name_into_parts: 1,
                                                    sanitize: 1,
                                                    clean_map_value: 1]

 import DraftGuru.Contexts.Utilities

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

    # to use for sorting
    allowed_fields = ["id", "position", "player_slug", "lane_agility_time", "shuttle_run",
    "three_quarter_sprint", "standing_vertical_leap", "max_vertical_leap",
    "max_bench_press_repetitions", "height_w_shoes", "height_wo_shoes", "body_fat_pct",
    "hand_length", "hand_length_inches", "hand_width", "standing_reach", "standing_reach_inches",
    "weight_lbs", "wingspan", "wingspan_inches", "height_w_shoes_inches", "height_wo_shoes_inches",
    "player_id", "player_name", "draft_year"]

    search_term = Map.get(params, "player_name")

    query = PlayerCombineStat

    query = maybe_apply_search(query, search_term, :player_name)

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, allowed_fields, params)

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

  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStat, id)

  def get_player_combine_stats_by_player_id!(layer_id), do: Repo.get_by!(PlayerCombineStat, layer_id)

  @doc """
  Atomically finds or creates a player, its ID lookup, and combine stats.

  Handles conflicts gracefully for ID lookup and combine stats.

  USED IN SEEDING DATA WHEN STARTING THE APPLICATION
  """
  def upsert_player_with_stats(attrs \\ %{}) do
    # --- 1. Prepare Attributes (Similar to your original create_player_combine_stats) ---
    keys_to_format = [
      :height_w_shoes, :height_wo_shoes, :standing_reach, :wingspan,
      :hand_length, :hand_width
    ]

    # Use :player_name from input attrs, ensure it's sanitized
    player_name = sanitize(attrs[:player_name])
    # Start building combine_stats_attrs, ensuring player_name is present
    combine_stats_attrs = Map.put(attrs, :player_name, player_name)

    # convert measurements to inches
    combine_stats_attrs = Enum.reduce(keys_to_format, combine_stats_attrs, fn key, acc ->
      value = Map.get(acc, key)
      inches_key = String.to_atom("#{key}_inches")
      Map.put(acc, inches_key, clean_map_value(value))
    end)

    # get the attributes for the player_canonical table
    canonical_attrs =
      %{}
      |> Map.merge(split_name_into_parts(player_name)) # Use sanitized name

    # Use draft_year from input attrs
    draft_year_str = to_string(attrs[:draft_year]) # Ensure it's a string for concatenation if needed

    # Generate player_slug (ensure parts are not nil before joining)
    slug_parts = [
      canonical_attrs[:first_name],
      canonical_attrs[:middle_name], # Handle potential nil
      canonical_attrs[:last_name],
      canonical_attrs[:suffix],      # Handle potential nil
      draft_year_str                 # Use draft year from input
    ]
    |> Enum.reject(&is_nil/1)        # Remove nils
    |> Enum.reject(&(&1 == ""))      # Remove empty strings
    |> Enum.map(&to_string/1)        # Ensure all parts are strings
    |> Enum.join("_")                # Join with underscore

    player_slug = String.replace(slug_parts, "__", "_") # Clean up double underscores if middle/suffix were nil/empty

    # Add player_slug to combine_stats_attrs
    combine_stats_attrs = Map.put(combine_stats_attrs, :player_slug, player_slug)

    player_id_attrs = %{
      data_source_id: player_slug, # Use the calculated slug
      data_source: "nba.com/stats/draft"
    }

    # --- 2. Build the Ecto.Multi Transaction ---
    Multi.new()
    |> Multi.run(:find_or_create_player, fn repo, _changes ->
      # Try to find the player using the exact match function
      case Players.get_player_by_name(canonical_attrs) do
        nil ->
          # Not found, prepare to insert
          Player.changeset(%Player{}, canonical_attrs)
          |> Multi.insert_changeset(:player_canonical) # Use a nested Multi operation name
        %Player{} = existing_player ->
          # Found, return it
          {:ok, existing_player}
      end
    end)
    |> Multi.run(:get_player_id, fn _repo, changes ->
        # Extract the player ID, whether it was found or newly inserted
        player = case changes do
          %{find_or_create_player: %{player_canonical: inserted}} -> inserted # From nested insert
          %{find_or_create_player: found} when is_struct(found, Player) -> found # From direct find
          _ -> nil # Should not happen if find_or_create_player succeeded
        end

        if player, do: {:ok, player.id}, else: {:error, :cannot_determine_player_id}
    end)
    |> Multi.insert(:player_id_lookup, fn %{get_player_id: player_id} ->
        lookup_attrs = Map.put(player_id_attrs, :player_id, player_id)
        PlayerIdLookup.changeset(%PlayerIdLookup{}, lookup_attrs)
      end,
      # If a lookup record with the same data_source/data_source_id exists, do nothing.
      # This assumes the player_id associated with that slug should not change.
      on_conflict: :nothing,
      conflict_target: [:data_source, :data_source_id] # Match unique index
    )
    |> Multi.insert(:player_combine_stats, fn %{get_player_id: player_id} ->
        stats_attrs_with_id = Map.put(combine_stats_attrs, :player_id, player_id)
        # Ensure required fields are present before creating changeset
        required_fields = [:player_slug, :player_name, :draft_year, :position, :player_id]
        if Enum.all?(required_fields, &(Map.has_key?(stats_attrs_with_id, &1) && !is_nil(Map.get(stats_attrs_with_id, &1)))) do
           PlayerCombineStat.changeset(%PlayerCombineStat{}, stats_attrs_with_id)
        else
           # If required fields are missing, return an error changeset immediately
           # This prevents the transaction from failing later on a validation error
           # and allows us to potentially log it more clearly.
           {:error, :missing_required_combine_stats_fields, stats_attrs_with_id}
        end
      end,
      # If stats with the same player_slug exist, do nothing.
      # Alternative: :replace_all to update if found, but :nothing seems safer for seeding.
      on_conflict: :nothing,
      conflict_target: :player_slug # Match unique index
    )
    |> Repo.transaction()
    |> case do
      {:ok, results} ->
        # You might want to check results[:player_id_lookup] and results[:player_combine_stats]
        # to see if they were :unchanged due to conflicts
        {:ok, results}
      {:error, :player_combine_stats, {:error, :missing_required_combine_stats_fields, data}, _changes} ->
        # Specific handling for our custom error
        IO.puts("Skipping combine stats due to missing required fields for slug: #{Map.get(data, :player_slug)}")
        {:error, :validation, %{reason: :missing_required_combine_stats_fields, data: data}} # Return a more informative error
      {:error, failed_step, error_value, _changes} ->
        # Handle other transaction failures (e.g., database errors, changeset errors)
        IO.puts("Transaction failed at step: #{failed_step}")
        IO.inspect(error_value, label: "Error Value")
        {:error, failed_step, error_value} # Propagate the error
    end
  end

  def create_player_combine_stats(attrs \\ %{}) do

    keys_to_format = [
      :height_w_shoes,
      :height_wo_shoes,
      :standing_reach,
      :wingspan,
      :hand_length,
      :hand_width
     ]

    # stri white sace and extra unctuation from layer name
    combine_stats_attrs = Map.put(attrs, :player_name, sanitize(attrs[:player_name]))

    # convert measurements to inches
    combine_stats_attrs = Enum.reduce(keys_to_format, combine_stats_attrs, fn key, acc ->
      value = Map.get(acc, key)
      inches_key = String.to_atom("#{key}_inches")
      Map.put(acc, inches_key, clean_map_value(value))
    end)

    # get the attributes for the layer_canonical table
    canonical_attrs =
      %{}
      |> Map.merge(split_name_into_parts(combine_stats_attrs[:player_name]))

    player_slug = "#{canonical_attrs[:first_name]}_#{canonical_attrs[:middle_name]}_#{canonical_attrs[:last_name]}_#{canonical_attrs[:suffix]}_#{attrs[:draft_year]}"
    combine_stats_attrs = Map.put(combine_stats_attrs, :player_slug, player_slug)

    player_id_attrs =
      %{}
      |> Map.put(:data_source_id, player_slug)
      |> Map.put(:data_source, "nba.com/stats/draft")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:player_canonical, Player.changeset(%Player{}, canonical_attrs))
    |> Ecto.Multi.insert(:player_id_lookup, fn %{player_canonical: player_canonical} ->
      PlayerIdLookup.changeset(%PlayerIdLookup{},
        Map.put(player_id_attrs, :player_id, player_canonical.id))
    end,
    on_conflict: :nothing,
    conflict_target: [:data_source, :data_source_id])
    |> Ecto.Multi.insert(:player_combine_stats, fn %{player_canonical: player_canonical} ->
      updated_combine_stats_attrs = Map.put(combine_stats_attrs, :player_id, player_canonical.id)
      PlayerCombineStat.changeset(%PlayerCombineStat{}, updated_combine_stats_attrs)
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

  def delete_player_combine_stats(%PlayerCombineStat{} = player) do
    Repo.delete(player)
  end

end

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
  alias Ecto.Multi

  alias DraftGuru.Players
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
    attrs = atomize_keys(attrs) # Atomize keys first

    keys_to_format = [
      :height_w_shoes, :height_wo_shoes, :standing_reach, :wingspan,
      :hand_length, :hand_width
    ]

    # Use :player_name from input attrs, ensure it's sanitized
    raw_player_name = Map.get(attrs, :player_name)


    player_name = sanitize(raw_player_name)
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
        %Player{} = existing_player ->
          # Found, return it wrapped in :ok tuple for Multi.run
          {:ok, existing_player}
        nil ->
          # Not found, create changeset and INSERT using Repo directly.
          # Repo.insert returns {:ok, player} or {:error, changeset},
          # which is the correct format for Multi.run's return value.
          changeset = Player.changeset(%Player{}, canonical_attrs)
          Repo.insert(changeset)
          # If you needed explicit repo: Repo.insert(repo, changeset)
      end
    end)
    |> Multi.run(:get_player_id, fn _repo, changes ->
        # Extract the player ID. The result from :find_or_create_player under the key
        # :find_or_create_player in the `changes` map will be the Player struct
        # itself if the find or the insert was successful.
        case changes do
          %{find_or_create_player: %Player{} = player} ->
            {:ok, player.id}
         # If Repo.insert failed in the previous step, it would have returned
         # {:error, changeset}, halting the Multi execution. So we primarily
         # need to handle the success case here. We add a catch-all for safety.
          _ ->
            IO.inspect(changes, label: "Unexpected changes map in :get_player_id step")
            {:error, :cannot_determine_player_id_from_previous_step_result}
        end
    end)
    |> Multi.insert(:player_id_lookup, fn %{get_player_id: player_id} ->
        # This part remains the same
        lookup_attrs = Map.put(player_id_attrs, :player_id, player_id)
        PlayerIdLookup.changeset(%PlayerIdLookup{}, lookup_attrs)
      end,
      on_conflict: :nothing,
      conflict_target: [:data_source, :data_source_id]
    )
    |> Multi.insert(:player_combine_stats, fn %{get_player_id: player_id} ->
        # This part remains the same
        stats_attrs_with_id = Map.put(combine_stats_attrs, :player_id, player_id)
        required_fields = [:player_slug, :player_name, :draft_year, :position, :player_id]
        if Enum.all?(required_fields, &(Map.has_key?(stats_attrs_with_id, &1) && !is_nil(Map.get(stats_attrs_with_id, &1)))) do
           PlayerCombineStat.changeset(%PlayerCombineStat{}, stats_attrs_with_id)
        else
           {:error, :missing_required_combine_stats_fields, stats_attrs_with_id}
        end
      end,
      on_conflict: :nothing,
      conflict_target: :player_slug
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
    attrs = atomize_keys(attrs) # Atomize keys first

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
    |> case do
      {:ok, results} ->
        {:ok, results}
      {:error, :player_combine_stats, {:error, :missing_required_combine_stats_fields, data}, _changes} ->
        # ... (existing handling) ...
        {:error, :validation, %{reason: :missing_required_combine_stats_fields, data: data}}
      {:error, :player_combine_stats, %Ecto.Changeset{} = invalid_changeset, _changes} -> # <--- ADD THIS CLAUSE
        # This catches validation errors from PlayerCombineStat.changeset/2
        ChangesetLogger.log_failure(invalid_changeset, %{module: DraftGuru.Players.PlayerCombineStat, reason: "validation"})
        # Return an error tuple consistent with other failures
        {:error, :player_combine_stats_validation, invalid_changeset}
      {:error, failed_step, error_value, _changes} ->
        # This handles other errors (DB errors, other steps failing)
        # You could add more specific logging here if needed
        IO.puts("Transaction failed at step: #{failed_step}")
        IO.inspect(error_value, label: "Error Value")
        # Log if it's a changeset error from a *different* step
        if is_struct(error_value, Ecto.Changeset) do
          ChangesetLogger.log_failure(error_value, %{module: "Unknown", step: failed_step})
        end
        {:error, failed_step, error_value}
    end

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

  # --- Private Helpers ---

  @doc """
  Converts string keys in a map to atom keys.
  """
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {String.to_atom(key), value} end)
  end

end

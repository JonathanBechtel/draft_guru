# lib/draft_guru/player_infos.ex
defmodule DraftGuru.PlayerInfos do
  @moduledoc """
  The PlayerInfos context. Handles player biographical info and images.
  """

  import Ecto.Query, warn: false
  import DraftGuru.Contexts.Utilities # Reuse your existing utilities

  alias DraftGuru.Repo
  alias DraftGuru.Players.{Player, PlayerInfo}

  @doc """
  Returns the list of player_infos, optionally filtered and sorted.
  Preloads the associated player_canonical record.
  """
  def list_player_infos(params \\ %{}) do
    allowed_fields = ["id", "birth_year", "school", "league", "player_id", "inserted_at"] # Add player name via join later if needed for sorting

    query = from(pi in PlayerInfo, preload: [:player_canonical])

    # Optional: Add search functionality (e.g., by school or joined player name)
    # search_term = Map.get(params, "search")
    # query = maybe_apply_search(query, search_term, [:school, :league]) # Adjust columns as needed

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, allowed_fields, params)

    page = to_integer_with_default(Map.get(params, "page"), 1)
    page_size = 20 # Adjust page size as needed
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

  @doc """
  Gets a single player_info record by ID, preloading the player_canonical.

  Raises `Ecto.NoResultsError` if the PlayerInfo does not exist.
  """
  def get_player_info!(id), do: Repo.get!(PlayerInfo, id) |> Repo.preload(:player_canonical)

   @doc """
  Gets a single player_info record by Player ID, preloading the player_canonical.
  Returns nil if not found.
  """
  def get_player_info_by_player_id(player_id) do
     Repo.get_by(PlayerInfo, player_id: player_id) |> Repo.preload(:player_canonical)
  end


  @doc """
  Creates a player_info record.

  Requires `attrs` containing the image uploads and other fields.
  The `:player_id` must correspond to an existing `Player` record.
  """
  def create_player_info(attrs \\ %{}) do
    %PlayerInfo{}
    |> PlayerInfo.changeset(attrs)
    # Waffle requires the changeset to be applied before insert/update
    # if you need access to the scope (like player_id) in the uploader filename/path.
    # Ecto.Multi makes this clean.
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
        {:ok, player_info_struct} -> Repo.insert(player_info_struct)
        {:error, changeset} -> {:error, changeset}
       end
  end

  @doc """
  Updates a player_info record.

  Handles updating attributes and potentially replacing images.
  """
  def update_player_info(%PlayerInfo{} = player_info, attrs) do
     player_info
     |> PlayerInfo.changeset(attrs)
     # Apply action before update to allow Waffle access to scope
     |> Ecto.Changeset.apply_action(:update)
     |> case do
        {:ok, player_info_struct} -> Repo.update(player_info_struct)
        {:error, changeset} -> {:error, changeset}
       end
  end

  @doc """
  Deletes a player_info record.

  Waffle does not automatically delete files from storage by default.
  You might need to add custom logic or use background jobs if you
  need automatic cleanup on S3, etc. For local storage, files remain.
  """
  def delete_player_info(%PlayerInfo{} = player_info) do
    # Optional: Add logic here to delete files from storage if needed,
    # using Waffle.Storage.delete/2 before Repo.delete.
    # Waffle.Storage.delete(ImageUploader.Type.cast(player_info.headshot))
    # Waffle.Storage.delete(ImageUploader.Type.cast(player_info.stylized_image))
    Repo.delete(player_info)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player_info changes.
  """
  def change_player_info(%PlayerInfo{} = player_info, attrs \\ %{}) do
    PlayerInfo.changeset(player_info, attrs)
  end

  @doc """
  Returns a list of {Player Name, Player ID} for use in select dropdowns.
  """
  def list_players_for_select do
    from(p in Player,
    order_by: [asc: p.last_name, asc: p.first_name],
    select: {
      fragment("? || ' ' || ? || COALESCE(' (' || ? || ')', '')",
        p.first_name,
        p.last_name,
        p.suffix
      ),
      p.id
    }
  )
    |> Repo.all()
  end
end

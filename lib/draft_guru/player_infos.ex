# lib/draft_guru/player_infos.ex
defmodule DraftGuru.PlayerInfos do
  @moduledoc """
  The PlayerInfos context. Handles player biographical info and images.
  """

  import Ecto.Query, warn: false
  # Reuse your existing utilities
  import DraftGuru.Contexts.Utilities

  alias DraftGuru.Repo
  alias DraftGuru.ImageUploader
  alias DraftGuru.Players.{Player, PlayerInfo}

  @doc """
  Returns the list of player_infos, optionally filtered and sorted.
  Preloads the associated player_canonical record.
  """
  def list_player_infos(params \\ %{}) do
    # Add player name via join later if needed for sorting
    allowed_fields = ["id", "birth_date", "school", "league",  "player_id", "inserted_at"]

    query = from(pi in PlayerInfo, preload: [:player_canonical])

    # Search by player name (first or last name)
    search_term = Map.get(params, "search")

    query = if search_term && search_term != "" do
      from pi in query,
        join: p in assoc(pi, :player_canonical),
        where: ilike(p.first_name, ^"%#{search_term}%") or
               ilike(p.last_name, ^"%#{search_term}%")
        else
          query
    end

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, allowed_fields, params)

    page = to_integer_with_default(Map.get(params, "page"), 1)
    # Adjust page size as needed
    page_size = 20
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
    attrs = ImageUploader.process_player_attrs_upload_data(attrs)
    %PlayerInfo{}
    |> PlayerInfo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player_info record.

  Handles updating attributes and potentially replacing images.
  """
  def update_player_info(%PlayerInfo{} = player_info, attrs) do
    # Process uploads when files are present, regardless of replacement flags
    processed_attrs = attrs
      |> process_upload_if_present("headshot")
      |> process_upload_if_present("stylized_image")

    # Handle removals if checkboxes are checked
    final_attrs = processed_attrs
      |> handle_image_removal("headshot_path", player_info.headshot_path, attrs["remove_headshot"])
      |> handle_image_removal("stylized_image_path", player_info.stylized_image_path, attrs["remove_stylized_image"])

    player_info
    |> PlayerInfo.changeset(final_attrs)
    |> Repo.update()
  end

  # Process the upload if a file is present in the params
  defp process_upload_if_present(attrs, image_type) do
    if _upload = attrs[image_type], do: ImageUploader.process_image_upload(attrs, image_type), else: attrs
  end

  # Handle image removal based on checkbox
  defp handle_image_removal(attrs, path_key, _existing_path, "true"), do: Map.put(attrs, path_key, nil)
  defp handle_image_removal(attrs, path_key, existing_path, _) do
    # Keep existing path if there's no new upload
    if Map.has_key?(attrs, path_key), do: attrs, else: Map.put(attrs, path_key, existing_path)
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
        fragment(
          "? || ' ' || ? || COALESCE(' (' || ? || ')', '')",
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

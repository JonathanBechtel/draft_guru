# lib/draft_guru/player_infos.ex
defmodule DraftGuru.PlayerInfos do
  @moduledoc """
  The PlayerInfos context. Handles biographical data and image uploads for players.
  """

  import Ecto.Query, warn: false
  alias DraftGuru.Repo

  alias DraftGuru.Players.PlayerInfo
  alias DraftGuru.Players.Player # Alias the canonical player schema

  # --- Configuration Helpers ---

  defp uploads_base_dir do
    Application.fetch_env!(:draft_guru, __MODULE__)[:uploads_base_dir]
  end

  defp uploads_static_path do
     Application.fetch_env!(:draft_guru, __MODULE__)[:uploads_static_path]
  end

  # --- Public API ---

  @doc """
  Returns the list of player_info records, preloading the associated player.

  Accepts params for pagination and sorting (similar to other contexts).
  """
  def list_player_infos(params \\ %{}) do
    # TODO: Implement pagination/sorting/searching similar to Players context if needed
    # For now, just list all, preloading player names
    PlayerInfo
    |> preload(:player_canonical)
    |> Repo.all()
  end

  @doc """
  Gets a single player_info record by ID, preloading the player.

  Raises `Ecto.NoResultsError` if the PlayerInfo does not exist.
  """
  def get_player_info!(id), do: Repo.get!(PlayerInfo, id) |> Repo.preload(:player_canonical)

  @doc """
  Gets a single player_info record by the canonical player ID.

  Returns `nil` if the PlayerInfo does not exist.
  """
  def get_player_info_by_canonical_id(player_id) do
    Repo.get_by(PlayerInfo, player_id: player_id) |> Repo.preload(:player_canonical)
  end

  @doc """
  Creates a player_info record, handling image uploads.

  ## Attributes

    * `attrs` - Map of attributes including biographical data and potentially
      `:headshot` and `:stylized_image` keys holding `Plug.Upload` structs.

  ## Examples

      iex> create_player_info(%{player_id: 1, birth_year: 2003, headshot: %Plug.Upload{...}})
      {:ok, %PlayerInfo{}}

      iex> create_player_info(%{birth_year: 2000})
      {:error, %Ecto.Changeset{}}

  """
  def create_player_info(attrs \\ %{}) do
    %PlayerInfo{}
    |> PlayerInfo.changeset(attrs)
    |> Ecto.Multi.new()
    |> handle_uploads_multi(:insert)
    |> Repo.transaction()
    |> case do
         {:ok, %{insert: player_info}} -> {:ok, player_info}
         {:error, :insert, changeset, _} -> {:error, changeset}
         # Handle potential file system errors during commit
         {:error, _, error, _} -> {:error, error}
       end
  end

  @doc """
  Updates a player_info record, handling image uploads and deleting old images.
  """
  def update_player_info(%PlayerInfo{} = player_info, attrs) do
    player_info
    |> PlayerInfo.changeset(attrs)
    |> Ecto.Multi.new()
    |> handle_uploads_multi(:update, player_info) # Pass original struct for deletion logic
    |> Repo.transaction()
     |> case do
         {:ok, %{update: updated_player_info}} -> {:ok, updated_player_info}
         {:error, :update, changeset, _} -> {:error, changeset}
         # Handle potential file system errors during commit
         {:error, _, error, _} -> {:error, error}
       end
  end

  @doc """
  Deletes a player_info record and its associated images.
  """
  def delete_player_info(%PlayerInfo{} = player_info) do
     Ecto.Multi.new()
     |> delete_upload_multi(:headshot, player_info.headshot_path)
     |> delete_upload_multi(:stylized_image, player_info.stylized_image_path)
     |> Ecto.Multi.delete(:delete, player_info)
     |> Repo.transaction()
     |> case do
          {:ok, %{delete: deleted_player_info}} -> {:ok, deleted_player_info}
          # Handle potential file system errors during commit
          {:error, _, error, _} -> {:error, error}
        end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player_info changes.
  """
  def change_player_info(%PlayerInfo{} = player_info, attrs \\ %{}) do
    PlayerInfo.changeset(player_info, attrs)
  end

  @doc """
  Generates a URL for accessing an uploaded image.
  """
  def image_url(%PlayerInfo{} = player_info, field) when field in [:headshot, :stylized_image] do
    path = Map.get(player_info, :"#{field}_path")
    if path, do: Path.join(uploads_static_path(), path), else: nil
  end

  @doc """
    Generates a URL for the serving endpoint. Needed for production with volumes.
  """
  def serve_upload_url(%PlayerInfo{} = player_info, field) when field in [:headshot, :stylized_image] do
    # Path generation needs the router helpers, often done in the HTML module or controller.
    # We return the necessary components here.
     path_field = Map.get(player_info, :"#{field}_path")
     if path_field do
      {:ok, player_info.id, field}
     else
      nil
     end
  end

  @doc """
  Returns a map of players suitable for a select dropdown, excluding those
  who already have associated player_info.
  """
  def list_players_for_select() do
     existing_player_ids_query = from(pi in PlayerInfo, select: pi.player_id)

     query =
       from p in Player,
       where: p.id not in subquery(existing_player_ids_query),
       order_by: [asc: p.last_name, asc: p.first_name],
       select: {fragment("? || ' ' || ?", p.first_name, p.last_name), p.id}

     Repo.all(query)
  end


  # --- Private Helpers ---

  # Adds upload/delete operations to an Ecto.Multi struct
  defp handle_uploads_multi(multi, :insert, changeset) do
    multi
    |> Ecto.Multi.run(:headshot_upload, fn _repo, _changes ->
        handle_upload(changeset, :headshot)
       end)
    |> Ecto.Multi.run(:stylized_image_upload, fn _repo, _changes ->
         handle_upload(changeset, :stylized_image)
        end)
    |> Ecto.Multi.insert(:insert, fn %{headshot_upload: headshot_path, stylized_image_upload: stylized_image_path} ->
         # Apply the generated paths back to the changeset before insert
         changeset
         |> put_change(:headshot_path, headshot_path)
         |> put_change(:stylized_image_path, stylized_image_path)
       end)
  end

  defp handle_uploads_multi(multi, :update, %PlayerInfo{} = original_player_info, changeset) do
    multi
    |> Ecto.Multi.run(:headshot_upload, fn _repo, _changes ->
         handle_upload(changeset, :headshot, original_player_info.headshot_path) # Pass old path for deletion
        end)
    |> Ecto.Multi.run(:stylized_image_upload, fn _repo, _changes ->
         handle_upload(changeset, :stylized_image, original_player_info.stylized_image_path) # Pass old path for deletion
        end)
    |> Ecto.Multi.update(:update, fn %{headshot_upload: headshot_path, stylized_image_upload: stylized_image_path} ->
        # Apply the generated paths back to the changeset before update
         changeset
         |> put_change(:headshot_path, headshot_path)
         |> put_change(:stylized_image_path, stylized_image_path)
        end)

  end

  # Handles a single file upload within an Ecto.Multi transaction run
  # Deletes the old file if a new one is provided and an old_path exists.
  defp handle_upload(changeset, field, old_path \\ nil) do
    case get_change(changeset, field) do
      %Plug.Upload{} = upload ->
        # Delete old file first if it exists
        delete_upload(old_path)
        # Generate new path and copy file
        dest_path = generate_upload_path(upload.filename)
        dest_full_path = Path.join(uploads_base_dir(), dest_path)
        # Ensure directory exists
        File.mkdir_p!(Path.dirname(dest_full_path))
        # Copy file
        case File.cp(upload.path, dest_full_path) do
          :ok -> {:ok, dest_path} # Return relative path for DB
          {:error, reason} -> {:error, "Failed to copy upload for #{field}: #{reason}"}
        end
      # Handle nil or :ignore if you add file deletion checkboxes
      _ ->
        # No new upload, keep the old path (or nil if none)
        {:ok, old_path}
    end
  end

  # Generates a unique relative path for an upload
  defp generate_upload_path(original_filename) do
    extension = Path.extname(original_filename)
    # Add timestamp and random string for uniqueness
    timestamp = :os.system_time(:millisecond)
    random_string = :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
    unique_filename = "#{timestamp}-#{random_string}#{extension}"
    # Optionally, create subdirectories, e.g., based on year/month
    # Path.join(["player_info", unique_filename])
    unique_filename # Store directly in the base upload dir for simplicity here
  end

  # Adds a file deletion step to an Ecto.Multi transaction
  defp delete_upload_multi(multi, multi_key, path) do
    Ecto.Multi.run(multi, multi_key, fn _repo, _changes ->
      delete_upload(path)
      {:ok, path} # Return ok even if file didn't exist
    end)
  end

  # Safely deletes a file given its relative path
  defp delete_upload(nil), do: :ok
  defp delete_upload(""), do: :ok
  defp delete_upload(relative_path) do
    full_path = Path.join(uploads_base_dir(), relative_path)
    case File.rm(full_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok # File already gone, that's fine
      {:error, reason} ->
        # Log the error but don't necessarily fail the whole transaction
        # depending on requirements. Here we just log.
        Logger.error("Failed to delete upload at #{full_path}: #{inspect(reason)}")
        :ok # Or return {:error, reason} to halt the multi
    end
  end
end

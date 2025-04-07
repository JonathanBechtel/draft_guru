defmodule DraftGuru.ImageUploader do
  require Logger

  @upload_root Application.compile_env(:draft_guru, :upload_dir, "imgs")

  @doc """
  Processes player attributes with file uploads and saves files to disk.
  Returns updated attributes with file paths.
  """
  def process_player_attrs_upload_data(player_attrs) do
    player_attrs
    |> process_image_upload("headshot")
    |> process_image_upload("stylized_image")
  end

  @doc """
  Processes a single image upload for the given image type.
  Returns the updated player_attrs map.
  """
  def process_image_upload(player_attrs, image_type) do
    upload = player_attrs[image_type]
    player_id = player_attrs["player_id"]

    cond do
      is_nil(upload) ->
        Logger.info("No #{image_type} file uploaded")
        player_attrs

      is_nil(player_id) ->
        Logger.error("No player_id provided for #{image_type} upload")
        player_attrs

      true ->
        # Generate filename
        file_ext = Path.extname(upload.filename)
        filename = generate_player_filename(player_id, file_ext, image_type)

        # Ensure player directory exists
        player_dir_path = Path.join(@upload_root, to_string(player_id))
        unless File.dir?(player_dir_path) do
          File.mkdir_p!(player_dir_path)
        end

        # Save file
        dest_path = generate_file_upload_path(player_id, filename)
        case File.cp(upload.path, dest_path) do
          :ok ->
            Logger.info("Successfully saved #{image_type} to #{dest_path}")
            Map.put(player_attrs, "#{image_type}_path", dest_path)

          {:error, reason} ->
            Logger.error("Failed to save #{image_type}: #{inspect(reason)}")
            player_attrs
        end
    end
  end

  @doc """
  Generates a file path for an uploaded file.
  """
  def generate_file_upload_path(subject_id, filename) do
    Path.join([@upload_root, to_string(subject_id), filename])
  end

  @doc """
  Generates a unique filename for a player image.
  """
  def generate_player_filename(player_id, file_ext, image_type) do
    file_datetime = NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)
      |> NaiveDateTime.to_string()
      |> String.replace(~r/[- :]/, "_")

    # skip the '.' because already included in file_ext
    "#{player_id}_#{image_type}_#{file_datetime}#{file_ext}"
  end
end

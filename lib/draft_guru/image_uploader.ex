# lib/draft_guru/image_uploader.ex
defmodule DraftGuru.ImageUploader do
  use Waffle.Definition

  # Define Waffle.Storage.Local or Waffle.Storage.S3, etc.
  # This is often overridden by environment-specific config.
  @impl Waffle.Definition
  def storage, do: Application.compile_env!(:waffle, :storage)

  # Provide a default storage directory
  # This will be prepended with the storage path from config
  @impl Waffle.Definition
  def storage_dir(_version, {_file, scope}) do
    # Example: scope could be a PlayerInfo struct
    player_id = scope.player_id || "misc"
    "player_images/#{player_id}"
  end

  # Image transformations (optional, add :imagemagick or :mogrify dep if used)
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 100x100^ -gravity center -extent 100x100", :png}
  # end

  # Fallback image URL
  @impl Waffle.Definition
  def default_url(_version, _scope) do
    # Consider adding a default placeholder image to priv/static/images
    "/images/default_avatar.png"
  end

  # Whitelist file extensions
  @impl Waffle.Definition
  def validate({file, _scope}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define maximum file size (e.g., 10MB)
  @impl Waffle.Definition
  def max_filesize, do: 10 * 1024 * 1024 # 10 megabytes

  # Optionally add object ACL for S3 uploads if needed (e.g., :public_read)
  # def acl(:public_read, _scope), do: :public_read
  # def acl(_version, _scope), do: :public_read # Default to public_read if needed

  # Override the default filename to something unique and predictable.
  # Using the original filename is generally discouraged for security reasons.
  @impl Waffle.Definition
  def filename(version, {_file, scope}) do
    # Example: use player_id and field name (headshot/stylized_image)
    player_id = scope.player_id || "misc"
    timestamp = System.system_time(:millisecond)
    field = scope.__struct__.waffle_field() # Get the field name from scope (:headshot or :stylized_image)
    ext = scope.__struct__.waffle_ext()     # Get the file extension from scope

    "#{field}-#{player_id}-#{timestamp}-#{version}#{ext}"
  end
end

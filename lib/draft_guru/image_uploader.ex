defmodule DraftGuru.ImageUploader do
  use Waffle.Definition

  # Evaluate the :waffle :storage configuration at compile time:
  @storage Application.compile_env(:waffle, :storage, Waffle.Storage.Local)

  def storage do
    @storage
  end

  # Remove the @impl annotations since Waffle doesn't define a formal behavior
  def storage_dir(_version, {_file, scope}) do
    player_id = scope.player_id || "misc"
    "player_images/#{player_id}"
  end

  def default_url(_version, _scope), do: "/images/default_avatar.png"

  def validate({file, _scope}) do
    ~w(.jpg .jpeg .gif .png)
    |> Enum.member?(Path.extname(file.file_name))
  end

  # Regular function (not a callback)
  def max_filesize, do: 10 * 1024 * 1024

  def filename(version, {_file, scope}) do
    player_id = scope.player_id || "misc"
    timestamp = System.system_time(:millisecond)
    field = scope.__struct__.waffle_field()
    ext   = scope.__struct__.waffle_ext()

    "#{field}-#{player_id}-#{timestamp}-#{version}#{ext}"
  end
end

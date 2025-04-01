defmodule DraftGuru.ImageUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

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

  def filename(version, {file, player_info}) do
    player_id = player_info.player_id || "misc"
    timestamp = System.system_time(:millisecond)

    # TO DO:  provide the ability to detect which version
    # of the image it is:  stylized or headshot

    "#{player_id}-#{timestamp}-#{version}"
  end

end

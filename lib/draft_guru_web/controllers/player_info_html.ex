# lib/draft_guru_web/controllers/player_info_html.ex
defmodule DraftGuruWeb.PlayerInfoHTML do
  use DraftGuruWeb, :html

  alias DraftGuru.ImageUploader # Alias your uploader

  embed_templates "player_info_html/*"

  # Helper function to get the URL for a Waffle attachment
  # It handles different storage backends (Local, S3)
  def image_url(attachment, version \\ :original) when not is_nil(attachment) do
    # Ensure we have a map or struct before calling url
    file = ImageUploader.Type.cast(attachment)
    ImageUploader.url({file, attachment}, version)
  end

  # Fallback if attachment is nil
  def image_url(nil, version \\ :original) do
    ImageUploader.default_url(version, nil)
  end

  # Reuse your existing sort toggle helper
  def toggle_sort(current_field, current_direction, clicked_field) do
    if current_field == clicked_field do
      if current_direction == "asc", do: "desc", else: "asc"
    else
      "asc"
    end
  end
end

defmodule DraftGuruWeb.PlayerInfoHTML do
  use DraftGuruWeb, :html

  alias DraftGuru.ImageUploader

  embed_templates "player_info_html/*"

  # Helper function to get the URL for a Waffle attachment
  # It handles different storage backends (Local, S3).

  # Define the function signature with the default for `version`.
  def image_url(attachment, version \\ :original)

  # Fallback clause if `attachment` is nil.
  def image_url(nil, version) do
    ImageUploader.default_url(version, nil)
  end

  # Clause when `attachment` is not nil.
  def image_url(attachment, version) do
    # Ensure we have a map or struct before calling url
    ImageUploader.url({attachment, nil}, version)
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

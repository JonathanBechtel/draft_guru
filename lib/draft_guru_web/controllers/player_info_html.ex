defmodule DraftGuruWeb.PlayerInfoHTML do
  use DraftGuruWeb, :html

  embed_templates "player_info_html/*"

  def toggle_sort(current_field, current_direction, clicked_field) do
    if current_field == clicked_field do
      if current_direction == "asc", do: "desc", else: "asc"
    else
      "asc"
    end
  end

  def image_url(player_info, field_name) when is_atom(field_name) do
    path = Map.get(player_info, field_name)
    image_url(path)
  end

  def image_url(nil), do: "/uploads/default_avatar.png"

  def image_url(path) when is_binary(path) do
    # Convert filesystem path to web URL
    # We assume the path is something like "imgs/player_id/filename.jpg"
    # and make it "/uploads/player_id/filename.jpg"
    path
    |> String.replace_prefix("imgs/", "/uploads/")
  end

end

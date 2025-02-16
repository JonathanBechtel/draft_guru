defmodule DraftGuruWeb.PlayerHTML do
  use DraftGuruWeb, :html

  embed_templates "player_html/*"

  # Simple function to toggle sort direction
  def toggle_sort(current_field, current_direction, clicked_field) do
    if current_field == clicked_field do
      if current_direction == "asc", do: "desc", else: "asc"
    else
      "asc"
    end
  end
end

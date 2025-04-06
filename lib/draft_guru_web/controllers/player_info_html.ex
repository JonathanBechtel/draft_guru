defmodule DraftGuruWeb.PlayerInfoHTML do
  use DraftGuruWeb, :html

  alias DraftGuru.ImageUploader
  alias DraftGuru.Players.PlayerInfo # Ensure PlayerInfo is aliased

  embed_templates "player_info_html/*"

  def image_url(scope, field, version \\ :original)

  def image_url(nil, _field, version) do
    # IO.inspect("image_url helper: Scope is nil", label: "DEBUG")
    ImageUploader.default_url(version, nil)
  end

  def image_url(%{} = scope, field, version) when is_atom(field) do
     file = Map.get(scope, field)
     # IO.inspect(scope, label: "DEBUG image_url: scope")
     # IO.inspect(field, label: "DEBUG image_url: field atom")
     # IO.inspect(file, label: "DEBUG image_url: file data retrieved") # See what 'file' contains

     cond do
       is_nil(file) ->
         # IO.inspect("image_url helper: file is nil, returning default", label: "DEBUG")
         ImageUploader.default_url(version, scope)

       is_map(file) or is_struct(file, Waffle.File) ->
         input_tuple = {file, scope}
         IO.inspect(input_tuple, label: "DEBUG image_url: Input to ImageUploader.url/2") # Check input
         result = ImageUploader.url(input_tuple, version)
         IO.inspect(result, label: "DEBUG image_url: Result FROM ImageUploader.url/2") # <<<--- THIS IS KEY
         # --- TEMPORARY WORKAROUND/TEST ---
         # Check if the result is the tuple, if so, force a default string for now
         # if result == input_tuple do
         #   IO.inspect("WORKAROUND: ImageUploader.url returned tuple, using default", label: "DEBUG")
         #   ImageUploader.default_url(version, scope)
         # else
         #   result # Return the actual result if it's a string
         # end
         # --- END TEMPORARY WORKAROUND ---
         result # Return the actual result

       # Check if file is just a string (maybe old data?)
       is_binary(file) ->
          IO.inspect(file, label: "DEBUG image_url: file is a binary string, maybe old path?")
          # Assuming the binary is the relative path, prepend asset_host
          Application.get_env(:waffle, Waffle.Storage.Local)[:asset_host] <> "/" <> file

       true ->
         IO.inspect("image_url helper: Unexpected file type, returning default. Type: #{inspect(file)}", label: "DEBUG")
         ImageUploader.default_url(version, scope)
     end
  end

  def image_url(scope, field, version) do
    IO.inspect("image_url helper: Catch-all triggered. scope=#{inspect(scope)}, field=#{inspect(field)}", label: "DEBUG")
    ImageUploader.default_url(version, scope)
  end

  # ... rest of the module
  def toggle_sort(current_field, current_direction, clicked_field) do
    if current_field == clicked_field do
      if current_direction == "asc", do: "desc", else: "asc"
    else
      "asc"
    end
  end

end

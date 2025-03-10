defmodule DraftGuru.Contexts.Utilities do
  @moduledoc """
  Module for helper functions to use throughout
  contexts.

  Mostly functions that make it easier to manipulate data that
  apply to multiple contexts.
  """
  import Ecto.Query, warn: false

  def apply_sorting(query, allowed_fields, params) do
    sort_field = Map.get(params, "sort_field", "id")
    sort_direction = Map.get(params, "sort_direction", "asc")

    sort_field =
      if sort_field in allowed_fields do
        sort_field
      else
        "id"
      end

    # convert sort_field to atom to use w/ ecto query
    sort_dir_atom =
      case sort_direction do
        "desc" -> :desc
        _ -> :asc
      end

    sort_field_atom = String.to_existing_atom(sort_field)

    from p in query,
      order_by: [{^sort_dir_atom, field(p, ^sort_field_atom)}]

  end

  def to_integer_with_default(nil, default), do: default
  def to_integer_with_default(str, default) do
    case Integer.parse(to_string(str)) do
      {int, _} -> int
      :error   -> default
    end
  end

  def maybe_apply_search(query, nil, _column), do: query
  def maybe_apply_search(query, "", _column), do: query
  def maybe_apply_search(query, search_term, column) do
    # Convert the column name to an atom if it's a string
    field = if is_binary(column), do: String.to_existing_atom(column), else: column

    from(p in query, where: ilike(field(p, ^field), ^"%#{search_term}%"))
  end
end

defmodule DraftGuru.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  import DraftGuru.Contexts.Utilities, only: [
    apply_sorting: 3,
    to_integer_with_default: 2
  ]

  alias DraftGuru.Repo
  alias DraftGuru.Players.Player

  @doc """
  Returns the list of player_canonical.

  ## Examples

      iex> list_player_canonical()
      [%Player{}, ...]

  """
def list_player_canonical(params \\ %{}) do
  # Start with a base query
  query = Player

  # used for sorting
  allowed_fields = [
    "id",
    "first_name",
     "middle_name",
    "last_name",
    "suffix",
    "inserted_at",
    "updated_at"
  ]

  # 1) Optionally filter by name
  query = maybe_apply_search(query, Map.get(params, "name"))

  record_count = Repo.aggregate(query, :count, :id)

  # 2) Sort by column/direction if provided
  query = apply_sorting(query, allowed_fields, params)

  # 3) Paginate at 100 rows/page
  page        = to_integer_with_default(Map.get(params, "page"), 1)
  page_size   = 100
  offset      = (page - 1) * page_size
  total_pages = ceil(record_count / page_size)

  query =
    query
    |> limit(^page_size)
    |> offset(^offset)

  records = Repo.all(query)

  %{
    records: records,
    total_pages: total_pages
  }
end

defp maybe_apply_search(query, nil), do: query
defp maybe_apply_search(query, ""),  do: query
defp maybe_apply_search(query, name) do
  from(p in query,
    where:
      ilike(p.first_name, ^"%#{name}%") or
      ilike(p.last_name, ^"%#{name}%")
  )
end

"""
defp apply_sorting(query, params) do
  allowed_fields    = ~w(id first_name middle_name last_name suffix inserted_at updated_at)
  sort_field        = Map.get(params, "sort_field", "id")
  sort_direction    = Map.get(params, "sort_direction", "asc")

  # Safeguard so a user cannot sort by bogus columns
  sort_field =
    if sort_field in allowed_fields do
      sort_field
    else
      "id"
    end

  # Convert string direction to :asc or :desc
  sort_dir_atom =
    case sort_direction do
      "desc" -> :desc
      _      -> :asc
    end

  sort_field_atom = String.to_existing_atom(sort_field)

  from q in query,
    order_by: [{^sort_dir_atom, field(q, ^sort_field_atom)}]
end
"""

#defp to_integer_with_default(nil, default), do: default
#defp to_integer_with_default(str, default) do
#  case Integer.parse(to_string(str)) do
#{int, _} -> int
#    :error   -> default
#  end

#end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)
  """
  def get_player!(id), do: Repo.get!(Player, id)

  def get_player_by_name(%{"suffix" => suffix,
                           "first_name" => first_name,
                           "middle_name" => middle_name,
                           "last_name" => last_name} = _player_map) do

      suffix      = if suffix == "", do: nil, else: suffix
      middle_name = if middle_name == "", do: nil, else: middle_name

      query =
        Player
        |> where([p], p.first_name == ^first_name)
        |> where([p], p.last_name == ^last_name)

      # If suffix is nil, we use is_nil(p.suffix); otherwise p.suffix == ^suffix
      query =
        if is_nil(suffix) do
          from(p in query, where: is_nil(p.suffix))
        else
          from(p in query, where: p.suffix == ^suffix)
        end

      # Similarly for `middle_name` if that can also be nil, etc.
      query =
        if is_nil(middle_name) do
          from(p in query, where: is_nil(p.middle_name))
        else
          from(p in query, where: p.middle_name == ^middle_name)
        end

      Repo.one(query)
  end

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end
end

defmodule DraftGuru.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias DraftGuru.Repo

  alias DraftGuru.Players.Player

  @doc """
  Returns the list of player_canonical.

  ## Examples

      iex> list_player_canonical()
      [%Player{}, ...]

  """
  def list_player_canonical(params \\ {}) do
    query = Player

    query =
      case Map.get(params, "name") do
        nil -> query

        "" -> query

        name ->
          from (p in query,
            where:
              ilike(p.first_name, ^"%#{name}%")) or
              ilike(p.last_name, ^"%#{name}%")
      end

    page_number = params["page"] |> to_integer_with_default(1)
    page_size = 100
    offset = (page_number - 1) * page_size

    query =
      query
      |> limit(^page_size)
      |> offset(^offset)

    Repo.all(query)
  end

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
                           "last_name" => last_name,
                           "draft_year" => draft_year} = _player_map) do

      suffix      = if suffix == "", do: nil, else: suffix
      middle_name = if middle_name == "", do: nil, else: middle_name

      query =
        Player
        |> where([p], p.first_name == ^first_name)
        |> where([p], p.last_name == ^last_name)
        |> where([p], p.draft_year == ^draft_year)

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

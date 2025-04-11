defmodule DraftGuru.PlayerIDLookups do
  @moduledoc """
  Module for the PlayerID context.
  """

  import Ecto.Query, warn: false
  import DraftGuru.Contexts.Utilities

  alias DraftGuru.Repo

  alias DraftGuru.Players.PlayerIdLookup

  @doc """
  Returns the list of all player_id_lookups, as modified by the search
  function
  """
  def list_player_id_lookups(params \\ %{}) do

    allowed_fields = ["id", "data_source", "data_source_id", "player_id"]

    search_term = Map.get(params, "idlookup")

    query = PlayerIdLookup

    query = maybe_apply_search(query, search_term, :data_source_id)

    record_count = Repo.aggregate(query, :count, :id)

    query = apply_sorting(query, allowed_fields, params)

    page = to_integer_with_default(Map.get(params, "page"), 1)
    page_size = 100
    offset = (page - 1) * page_size

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

  @doc """

  Gets a single id lookup

    ## Examples

      iex> get_id_lookup!(123)
      %PlayerIdLookup{}

      iex> get_player_id!(456)
      ** (Ecto.NoResultsError)
  """
  def get_lookup!(id), do: Repo.get!(PlayerIdLookup, id)

  def get_lookup_by_player_id(player_id), do: Repo.get_by(PlayerIdLookup,
                player_id: player_id)

  @doc """
  Creates the player id lookup

  ## Examples

      iex> create_id_lookup(%{field: value})
      {:ok, %PlayerIdLookup{}}

      iex> create_id_lookup(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_id_lookup(attrs \\ %{}) do
    %PlayerIdLookup{}
    |> PlayerIdLookup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player's id lookup
  """
  def update_player_id_lookup(%PlayerIdLookup{} = player_id_lookup, attrs) do
    player_id_lookup
    |> PlayerIdLookup.changeset(attrs)
    |> Repo.update()
  end
end

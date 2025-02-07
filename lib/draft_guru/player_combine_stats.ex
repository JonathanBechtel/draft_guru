defmodule DraftGuru.PlayerCombineStats do
  @moduledoc """
  Context for the PlayerCombineStats table
  """
  import Ecto.Query, warn: false
  alias DraftGuru.Repo
  alias DraftGuru.Players.PlayerCombineStats


  def get_player_combine_stats!(id), do: Repo.get!(PlayerCombineStats, id)

  def create_player_combine_stats(attrs \\ %{}) do
    %PlayerCombineStats{}
    |> Repo.changeset(attrs)
    |> Repo.insert()
  end
end

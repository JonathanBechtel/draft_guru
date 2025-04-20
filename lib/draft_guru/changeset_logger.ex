defmodule DraftGuru.ChangesetLogger do
  require Logger

  def log_failure(changeset, context \\ %{}) do
    Logger.error(fn ->
      context_str = if map_size(context) > 0, do: "[#{inspect(context)}] ", else: ""
      "#{context_str}Changeset validation failed. Errors: #{inspect(changeset.errors, pretty: true)}"
    end)

    # Optionally add more detailed debug logging
    # Logger.debug(fn ->
    #   "Failed changeset details: #{inspect(changeset, pretty: true, limit: :infinity)}"
    # end)
  end
end

defmodule Utilities do
  @moduledoc """
  This module is for helper functions that don't merit
  inclusion in another module.  Mostly for string formatting,
  date math, and file manipulation
  """

  def format_timestamp do

    NaiveDateTime.utc_now()
    |> NaiveDateTime.to_string()
    |> String.replace(":", "")
    |> String.replace(" ", "_")
    |> String.replace("-", "_")
    |> String.replace(".", "_")
  end

  def create_filename(base_name, file_suffix \\ ".csv") do

    timestamp = format_timestamp()

    "#{base_name}_#{timestamp}#{file_suffix}"
  end
end

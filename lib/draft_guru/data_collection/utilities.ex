@moduledoc """
This module is for helper functions that don't merit
inclusion in another module.  Mostly for string formatting,
date math, and file manipulation
"""

defmodule Utilities do

  def format_timestamp do

    NaiveDateTime.utc_now()
    |> String.replace(":", "")
    |> String.replace(" ", "_")
  end

  def create_filename(base_name, file_suffix = ".csv") do

    timestamp = format_timestamp()

    "base_name_#{timestamp}#{file_suffix}"
  end
end

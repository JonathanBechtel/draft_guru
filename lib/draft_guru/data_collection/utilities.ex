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

  @doc """
  Converts a list of maps to a CSV file.

  * `list_of_maps` is a list of maps (each map is a row).
  * The CSV headers are taken from all unique keys in the maps.
  * If a map is missing a key that is in the headers, its value is taken as `""`.

  ## Example

      iex> list_of_maps = [
      ...>   %{name: "Alice", age: 30, city: "NY"},
      ...>   %{name: "Bob", city: "LA"}
      ...> ]
      iex> MapsToCSV.write_to_csv(list_of_maps, "people.csv")

  Creates a file "people.csv" with headers: name,age,city
  and rows filled in accordingly.
  """
  def export_data_to_file(list_of_maps, combine_section) do
    # Collect all unique keys across all maps to form the CSV headers
    headers =
      list_of_maps
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()

    # Prepare the CSV lines:
    # 1) A header line (joined by commas)
    # 2) A line for each map (matching headers in the same order)
    csv_lines =
      [
        Enum.join(headers, ",")  # header row
        | Enum.map(list_of_maps, fn row_map ->
            headers
            |> Enum.map(fn key -> Map.get(row_map, key, "") end)
            |> Enum.join(",")
          end)
      ]
      |> Enum.join("\n")

    # create the filepath
    file_path = create_filename(combine_section)

    # Write the CSV string to the file
    File.write!(file_path, csv_lines)
  end
end

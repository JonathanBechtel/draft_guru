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
  def export_data_to_file(tuple_of_maps, combine_section,
                          directory_path \\ "lib/draft_guru/data_collection/data_files") do
    # Collect all unique keys across all maps to form the CSV headers
    {:ok, list_of_maps} = tuple_of_maps
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
    file_name = create_filename(combine_section)

    full_file_path = Path.join(directory_path, file_name)

    # Write the CSV string to the file
    File.write!(full_file_path, csv_lines)
  end

  @doc """
  Function to take whole string name from data and
  split into its associated first name, middle initial, last name, etc
  """
  def split_name_into_parts(name_string) do
    split_name = String.split(name_string)

    name_suffixes = [
      "ii", "iii", "iv", "jr", "sr", "junior", "senior",
    ]

    case split_name do
      [first, middle, last, suffix] ->
        %{first_name: first, middle_name: middle, last_name: last, suffix: suffix}

      [first, last] ->
        %{first_name: first, middle_name: nil, last_name: last, suffix: nil}

      [first] ->
        %{first_name: first, middle_name: nil, last_name: nil, suffix: nil}

      [first, middle, last] ->
        if sanitize(last) in name_suffixes do
          %{first_name: first, middle_name: nil, last_name: middle, suffix: last}

        else
          %{first_name: first, middle_name: middle, last_name: last, suffix: nil}
        end
    end

  end

  def sanitize(string) do
    string
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^[:alnum:]\s'\-]+/u, "")
  end

  def parse_draft_year(nil), do: "unknown"
  def parse_draft_year(year) when is_integer(year), do: year
  def parse_draft_year(year) when is_float(year), do: trunc(year)
  def parse_draft_year(year) when is_binary(year) do
    case Integer.parse(year) do
      {int, _} -> Integer.to_string(int)
      :error -> "invalid"
    end
  end
end

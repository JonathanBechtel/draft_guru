defmodule DraftGuru.NBADotComScraper do
  @moduledoc """
    A module responsible for fetching and parsing the draft data from
    NBA.com/stats/draft
  """

  require Logger
  alias HTTPoison.Response

  import Utilities
  use Wallaby.DSL

  # pull in the config from the applicatioin
  @base_url Application.compile_env!(:draft_guru, __MODULE__)[:base_url]

  @doc """
  Master function that runs fetch_html for multiple years
  """
  def pull_data_for_multiple_years(combine_section) do
    # NOTE:  hard coding these for now - can change later
    season_years = ["2024-25", "2023-24", "2022-23", "2021-22"]
    #  "2020-21", "2019-20", "2018-19", "2017-18", "2016-17", "2015-16",
    #  "2014-15", "2013-14", "2012-13", "2011-12", "2010-11", "2009-10",
    #  "2008-09", "2007-08", "2006-07", "2005-06", "2004-05", "2003-04", "2002-03",
    # "2001-02"]

    data = Enum.reduce(season_years, [], fn season_year, acc ->
      case fetch_combine_data(combine_section, season_year) do
        {:ok, body} -> acc ++ body
        {:error, reason} ->
          Logger.error("Failed to pull data for year: #{season_year}, because: #{reason}")
          acc
      end
    end)

    # loop over each map, update the key / value pair with the cleaned value
    data = Enum.map(data, fn player_map ->
      Map.new(player_map, fn {key, value} -> {key, clean_map_value(value)} end)
    end)

    case data do
      _ when is_list(data) -> {:ok, data}
      _ -> {:error, "Did not return correct type"}
    end

  end

  @doc """
    Fetch data from a section of the nba.com/stats/draft/{section} for a given year
  """

  def fetch_html(combine_section, season_year) do
    # Example:  https://nba.com/stats/draft/combine-anthro?SeasonYear=2024-25
    url = "#{@base_url}#{combine_section}?SeasonYear=#{season_year}"

    Logger.info("Fetching data for draft section: #{combine_section} in year #{season_year}")

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok,  %Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %Response{status_code: code}} ->
        {:error, "Received non-200 status code: #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_combine_data(combine_section, season_year) do
    {:ok, session} = Wallaby.start_session()

    url = "#{@base_url}#{combine_section}?SeasonYear=#{season_year}"

    # 1) Visit the page
    session = visit(session, url)

    # 2) 'Wait' for the table to appear by telling the query to wait up to 5 seconds
    table_tbody = Query.css("table.Crom_table__p1iZz > tbody.Crom_body__UYOcU", wait: 5_000)

    # 3) find/2 will raise an error if it doesn't appear in time
    _tbody_element = find(session, table_tbody)

    # 4) Now that the <tbody> definitely exists, let's collect all rows <tr>
    rows = all(session, Query.css("table.Crom_table__p1iZz > tbody.Crom_body__UYOcU > tr"))

    # 5) For each row, parse the <td> cells
    data =
      Enum.map(rows, fn row ->
        cells =
          row
          |> all(Query.css("td"))
          |> Enum.map(&Wallaby.Element.text/1)

        %{
          player_name:       Enum.at(cells, 0),
          position:          Enum.at(cells, 1),
          body_fat_pct:      Enum.at(cells, 2),
          hand_length:       Enum.at(cells, 3),
          hand_width:        Enum.at(cells, 4),
          height_wo_shoes:   Enum.at(cells, 5),
          height_w_shoes:    Enum.at(cells, 6),
          standing_reach:    Enum.at(cells, 7),
          weight_lbs:        Enum.at(cells, 8),
          wingspan:          Enum.at(cells, 9)
        }
      end)

    # End session & return data
    Wallaby.end_session(session)

    {:ok, data}
  end

  @doc """
  strips various formatted values of "no value" and returns nil value
  Used to handle incoming data from NBACom that doesn't contain a real value
  """
  defp parse_null_value("-%"), do: nil
  defp parse_null_value(_), do: nil
  defp parse_null_value(""), do: nil
  defp parse_null_value("nil"), do: nil

  defp parse_float(str) when is_binary(str) do
    case Float.parse(str) do
      {value, ""} -> value
      {value, _rest} -> value
      :error -> str
    end
  end

  defp parse_string_measurements(measurement) when is_binary(measurement) do
    regex = ~r/^(?<ft>\d+)'[\s]*(?<in>\d+(?:\.\d+)?)(?:"{0,2})?$/

    case regex.named_captures(regex, measurement) do
      %{"ft" => ft_str, "in" => in_str} ->
        {feet, _suffix} -> Integer.parse(ft_str)
        {inches, _suffix} -> Integer.parse(in_str)
        feet * 12 + inches

      # non measurement should show up here:  just return original value
      _ -> measurement
    end
  end

  def clean_map_value(value_name) do

    parsed_value = parse_null_value(value_name)

    case parsed_value do: nil -> nil end

    parsed_value = parse_float(value_name)

    case parsed_value do
      _ when is_float(parsed_value) -> parse_string_measurements(parsed_value)
      _ when is_binary(parsed_value) -> parsed_value
      _ -> parsed_value
    end
  end

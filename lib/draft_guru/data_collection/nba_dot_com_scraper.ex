defmodule DraftGuru.NBADotComScraper do
  @moduledoc """
    A module responsible for fetching and parsing the draft data from
    NBA.com/stats/draft
  """

  require Logger
  alias HTTPoison.Response

  use Wallaby.DSL

  # pull in the config from the applicatioin
  @base_url Application.compile_env!(:draft_guru, __MODULE__)[:base_url]

  @doc """
  Master function that runs fetch_html for multiple years
  """
  def scrape_data_for_multiple_years(combine_section) do
    # NOTE:  hard coding these for now - can change later
    season_years = ["2024-25", "2023-24", "2022-23", "2021-22",
      "2020-21", "2019-20", "2018-19", "2017-18", "2016-17", "2015-16",
      "2014-15", "2013-14", "2012-13", "2011-12", "2010-11", "2009-10",
      "2008-09", "2007-08", "2006-07", "2005-06", "2004-05", "2003-04", "2002-03",
     "2001-02"]

    data = Enum.reduce(season_years, [], fn season_year, acc ->
      case fetch_combine_data(combine_section, season_year) do
        {:ok, body} -> [body | acc]
        {:error, reason} ->
          Logger.error("Failed to pull data for year: #{season_year}, because: #{reason}")
          acc
      end
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

  @doc """
  Parse the main table out of the NBA combine HTML.

  Returns a list of maps—one per table row. You can adjust the selectors or column
  extraction logic as needed for other URLs/tables on nba.com.
  """
  def parse_combine_table(html) do
    # The table has a CSS class "Crom_table__p1iZz"
    # Each row is <tr>, each cell <td>.
    # We can find the <tbody> and parse each row.
    {:ok, document} = Floki.parse_document(html)

    # NOTE:  will need to see if classes differ by each page or not

    # Locate the table body by class:
    rows =
      document
      |> Floki.find("table.Crom_table__p1iZz > tbody.Crom_body__UYOcU > tr")

    # For each row (tr), we pluck out each cell (td) in order
    # We know from your snippet that columns are:
    #
    #  0: PLAYER
    #  1: POS
    #  2: BODY FAT %
    #  3: HAND LENGTH (inches)
    #  4: HAND WIDTH (inches)
    #  5: HEIGHT W/O SHOES
    #  6: HEIGHT W/ SHOES
    #  7: STANDING REACH
    #  8: WEIGHT (LBS)
    #  9: WINGSPAN
    #
    # Adjust as needed if the page changes.

    Enum.map(rows, fn row ->
      cells = Floki.find(row, "td") |> Enum.map(&Floki.text/1)

      %{
        player_name: Enum.at(cells, 0),
        position: Enum.at(cells, 1),
        body_fat_pct: Enum.at(cells, 2),
        hand_length: Enum.at(cells, 3),
        hand_width: Enum.at(cells, 4),
        height_wo_shoes: Enum.at(cells, 5),
        height_w_shoes: Enum.at(cells, 6),   # This might be empty if the site has no data
        standing_reach: Enum.at(cells, 7),
        weight_lbs: Enum.at(cells, 8),
        wingspan: Enum.at(cells, 9)
      }
    end)
  end

  @doc """
  Fetch and parse the NBA Draft Combine 'anthro' table for a given season year.

  Returns `{:ok, rows}` on success, or `{:error, reason}` if something goes wrong.
  """
  def fetch_and_parse(combine_section, season_year) do
    with {:ok, html} <- fetch_html(combine_section, season_year) do
      rows = parse_combine_table(html)
      {:ok, rows}
    end
  end

  @doc """
  Takes data retrieved from site, outputs to a csv
  """
  def output_data_to_csv(_list_data) do
    1
  end

  @doc """
  Scrabes nba draft website for multiple season years

  Returns {:ok, list} on success, or `{:error, reason}` if something goes wrong
  """
  def fetch_combine_data_multiple_years(combine_section, season_years) do
    Enum.reduce(season_years, [], fn season_year, acc ->
      case fetch_combine_data(combine_section, season_year) do
        {:ok, data} -> acc ++ data
        {:error, _reason} -> acc
        _ -> acc
      end
    end)
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
end

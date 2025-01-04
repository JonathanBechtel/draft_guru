defmodule DraftGuru.NBADotComScraper do
  @moduledoc """
    A module responsible for fetching and parsing the draft data from
    NBA.com/stats/draft
  """

  require Logger
  alias HTTPoison.Response

  # pull in the config from the applicatioin
  @base_url Application.compile_env!(:draft_guru, __MODULE__)[:base_url]

  @doc """
    Fetch data from a section of the nba.com/stats/draft/{section} for a given year
  """

  def fetch_html(combine_section, season_year) do
    # Example:  https://nba.com/stats/draft/combine-anthro?SeasonYear=2024-25
    url = "#{@base_url}#{combine_section}?SeasonYear=#{season_year}"

    Logger.info("Fetching data for draft section: #{combine_section} in year #{season_year}")

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok,  %Response{status_code:200, body: body}} ->
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
  def fetch_and_parse(season_year) do
    with {:ok, html} <- fetch_html(season_year) do
      rows = parse_combine_table(html)
      {:ok, rows}
    end
  end
end

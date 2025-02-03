defmodule DraftGuru.NBADotComScraper do
  @moduledoc """
    A module responsible for fetching and parsing the draft data from
    NBA.com/stats/draft
  """

  require Logger
  alias HTTPoison.Response

  import Utilities, only: [export_data_to_file: 2]
  use Wallaby.DSL

  # pull in the config from the applicatioin
  @base_url Application.compile_env!(:draft_guru, __MODULE__)[:base_url]
  @seasons Application.compile_env!(:draft_guru, __MODULE__)[:seasons]

  @doc """
  Master function that runs fetch_html for multiple years
  """

  def scrape_combine_data_for_section(combine_section) do
    combine_section
    |> scrape_data_for_multiple_years()
    |> clean_player_data()
    |> export_data_to_file(String.replace(combine_section, "-", "_"))
  end

  def scrape_data_for_multiple_years(combine_section) do
    Enum.reduce(@seasons, [], fn season_year, acc ->
      case fetch_combine_data(combine_section, season_year) do
        {:ok, body} -> acc ++ body
        {:error, _message} -> acc
      end
    end)
  end

  defp clean_player_data(data_list) do

   keys_to_format = [
    :height_w_shoes,
    :height_wo_shoes,
    :hand_length,
    :hand_width,
    :standing_reach,
    :wingspan
   ]

   data = Enum.map(data_list, fn player_map ->
      Enum.reduce(player_map, %{}, fn {key, value}, acc ->

        if key in keys_to_format do
          acc
          |> Map.put(key, value)
          |> Map.put("#{key}_inches", clean_map_value(value))
        else
          Map.put(acc, key, clean_map_value(value))
        end
      end)
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

  def format_player_map(combine_section, cells) do
    case combine_section do
      "combine-anthro" -> %{
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
      "combine-strength-agility" -> %{
        player_name: Enum.at(cells, 0),
        position: Enum.at(cells, 1),
        lane_agility_time: Enum.at(cells, 2),
        shuttle_run: Enum.at(cells, 3),
        three_quarter_sprint: Enum.at(cells, 4),
        standing_vertical_leap: Enum.at(cells, 5),
        max_vertical_leap: Enum.at(cells, 6),
        max_bench_press_repetitions: Enum.at(cells, 7)
      }
    end
  end

  def fetch_combine_data(combine_section, season_year) do
    {:ok, session} = Wallaby.start_session()

    url = "#{@base_url}#{combine_section}?SeasonYear=#{season_year}"

    IO.puts("Pulling data for url: #{url}")

    # 1) Visit the page
    session = visit(session, url)

    # 2) 'Wait' for the table to appear by telling the query to wait up to 5 seconds
    table_tbody = Query.css("table[class^='Crom_table__'] > tbody[class^='Crom_body__']", wait: 5_000)

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

        format_player_map(combine_section, cells)
      end)

    # End session & return data
    Wallaby.end_session(session)

    case data do
      _ when is_list(data) -> {:ok, data}
      _ -> {:error, "data did not return correctly"}
    end
  end

  @doc false
  defp parse_null_value("-%"), do: nil
  defp parse_null_value("_"), do: nil
  defp parse_null_value(""), do: nil
  defp parse_null_value("nil"), do: nil
  defp parse_null_value("-"), do: nil
  defp parse_null_value(nil), do: nil
  defp parse_null_value(value), do: value

  defp parse_non_null_value(value) do

    regex = ~r/^(?<ft>\d+)'[\s]*(?<in>\d+(?:\.\d+)?)(?:''|"{1,2})?$/

    case Regex.named_captures(regex, value) do

      %{"ft" => ft_str, "in" => in_str} ->
        feet = case Integer.parse(ft_str) do
          {value, _} -> value
          :error -> 0
        end

        inches = case Float.parse(in_str) do
          {value, _} -> value
          :error -> 0
        end
        feet * 12 + inches

        _ -> parse_float(value)
    end

  end

  defp parse_float(str) when is_binary(str) do

    case Float.parse(str) do
      {value, ""} -> value
      {value, _rest} -> value
      :error -> str
    end
  end

  def clean_map_value(value) do

    case parse_null_value(value) do
      nil -> nil
      not_nil_value -> parse_non_null_value(not_nil_value)
    end
  end

end

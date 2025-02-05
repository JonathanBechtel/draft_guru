# file to hold and load in data to use for other calculations
defmodule DraftGuru.DataLoader do
  @moduledoc """
  Loads and manipulates data for use inside the application
  """
  def load_data(file_path) do
    File.read!(file_path)
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_header(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp parse_rows(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&convert_to_number/1)
    end)
  end

  defp convert_to_number(data) do
    case Float.parse(data) do
      {float, ""} -> float
      _ -> data
    end
  end

  def create_dataset(file_path) do
    file_data = load_data(file_path)
    [header | rows] = file_data
    headers = parse_header(header)

    data_rows = parse_rows(rows)
    zipped_data = Enum.map(data_rows, fn row -> Enum.zip(headers, row) end)
    Enum.map(zipped_data, fn row -> Enum.into(row, %{})end)
  end
end

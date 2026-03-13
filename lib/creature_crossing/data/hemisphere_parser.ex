defmodule CreatureCrossing.Data.HemisphereParser do
  @moduledoc """
  Parses month range strings and time strings from wiki scraper output
  into the structured hemisphere data the overlap calculator expects.
  """

  @month_map %{
    "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4,
    "may" => 5, "jun" => 6, "jul" => 7, "aug" => 8,
    "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12,
    "january" => 1, "february" => 2, "march" => 3, "april" => 4,
    "june" => 6, "july" => 7, "august" => 8,
    "september" => 9, "october" => 10, "november" => 11, "december" => 12
  }

  @month_names %{
    1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr",
    5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug",
    9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"
  }

  @doc """
  Build the full hemisphere data map from a month-range string and time string.

  Returns a map like:
    %{
      "months_array" => [1, 2, 3, 9, 10, 11, 12],
      "times_by_month" => %{"1" => "4 AM – 7 PM", "2" => "4 AM – 7 PM", ...},
      "availability_array" => [%{"months" => "Sep - Jun", "time" => "4 AM – 7 PM"}]
    }
  """
  def build(months_str, time_str) do
    months_array = parse_months(months_str)
    times_by_month = build_times_by_month(months_array, time_str)
    availability_array = build_availability_array(months_str, time_str)

    %{
      "months_array" => months_array,
      "times_by_month" => times_by_month,
      "availability_array" => availability_array
    }
  end

  @doc """
  Parse a month range string into a sorted list of month integers.

  Examples:
    "Sep - Jun"       → [1, 2, 3, 4, 5, 6, 9, 10, 11, 12]
    "All year"        → [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    "Mar - May; Sep - Nov" → [3, 4, 5, 9, 10, 11]
  """
  def parse_months("All year"), do: Enum.to_list(1..12)
  def parse_months("all year"), do: Enum.to_list(1..12)

  def parse_months(str) do
    str
    |> String.split(~r/[;&]/)
    |> Enum.flat_map(&parse_single_month_range/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp parse_single_month_range(range_str) do
    range_str = String.trim(range_str)

    case String.split(range_str, ~r/\s*[\-\x{2013}\x{2014}]+\s*/u) do
      [start_str, end_str] ->
        start_month = month_number(String.trim(start_str))
        end_month = month_number(String.trim(end_str))

        if start_month && end_month do
          expand_month_range(start_month, end_month)
        else
          []
        end

      [single] ->
        case month_number(String.trim(single)) do
          nil -> []
          m -> [m]
        end

      _ ->
        []
    end
  end

  defp expand_month_range(start_m, end_m) when start_m <= end_m do
    Enum.to_list(start_m..end_m)
  end

  defp expand_month_range(start_m, end_m) do
    Enum.to_list(start_m..12) ++ Enum.to_list(1..end_m)
  end

  defp month_number(str) do
    Map.get(@month_map, String.downcase(str))
  end

  defp build_times_by_month(months_array, time_str) do
    Map.new(months_array, fn m -> {to_string(m), time_str} end)
  end

  defp build_availability_array(months_str, time_str) do
    months_str
    |> String.split(~r/[;&]/)
    |> Enum.map(fn range ->
      range = String.trim(range)

      months = parse_single_month_range(range)

      month_label =
        case months do
          [] ->
            range

          [single] ->
            @month_names[single]

          list ->
            "#{@month_names[List.first(list)]} – #{@month_names[List.last(list)]}"
        end

      %{"months" => month_label, "time" => time_str}
    end)
  end
end

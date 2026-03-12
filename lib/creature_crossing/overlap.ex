defmodule CreatureCrossing.Overlap do
  @moduledoc """
  Core overlap calculation engine for Creature Crossing.

  Given a list of selected critters and a hemisphere, finds the single best
  month + time window where the most critters are simultaneously catchable.
  """

  @month_names %{
    1 => "January", 2 => "February", 3 => "March", 4 => "April",
    5 => "May", 6 => "June", 7 => "July", 8 => "August",
    9 => "September", 10 => "October", 11 => "November", 12 => "December"
  }

  @doc """
  Calculates the best overlap for the given critters and hemisphere.

  Returns a map with:
    - `:month` — the best month name (e.g. "June"), or nil
    - `:time_range` — formatted time string (e.g. "1:00 PM - 3:00 PM"), or "No Overlap"
    - `:critter_count` — number of critters catchable in that window
    - `:critters` — list of critter maps available in that window
  """
  def calculate(critters, hemisphere) when hemisphere in ["north", "south"] do
    hemi_key = hemisphere

    # For each month 1-12, find which critters are available and their hours
    results =
      for month <- 1..12 do
        available =
          Enum.filter(critters, fn critter ->
            months = get_in(critter, [hemi_key, "months_array"]) || []
            month in months
          end)

        if available == [] do
          {month, 0, [], []}
        else
          # Build a set of available hours for each critter in this month
          hour_sets =
            Enum.map(available, fn critter ->
              time_str =
                get_in(critter, [hemi_key, "times_by_month", to_string(month)]) || "All day"

              {critter, parse_time_ranges(time_str)}
            end)

          # Count critters available at each hour (0-23)
          hour_counts =
            for hour <- 0..23 do
              matching =
                Enum.filter(hour_sets, fn {_critter, hours} ->
                  MapSet.member?(hours, hour)
                end)

              {hour, length(matching), Enum.map(matching, &elem(&1, 0))}
            end

          # Find the max overlap count
          max_count = hour_counts |> Enum.map(&elem(&1, 1)) |> Enum.max()

          # Get the consecutive range(s) with max overlap
          best_hours =
            hour_counts
            |> Enum.filter(fn {_h, count, _} -> count == max_count end)
            |> Enum.map(&elem(&1, 0))

          # Get critters from the first best hour
          {_, _, best_critters} =
            Enum.find(hour_counts, fn {h, _, _} -> h == hd(best_hours) end)

          {month, max_count, best_hours, best_critters}
        end
      end

    # Find the month with the highest overlap
    {best_month, best_count, best_hours, best_critters} =
      Enum.max_by(results, &elem(&1, 1))

    if best_count == 0 do
      %{
        month: nil,
        time_range: "No Overlap",
        critter_count: 0,
        critters: []
      }
    else
      %{
        month: @month_names[best_month],
        time_range: format_time_range(best_hours),
        critter_count: best_count,
        critters: best_critters
      }
    end
  end

  @doc """
  Parses a Nookipedia time string into a MapSet of hours (0-23).

  Handles:
    - "All day" → all 24 hours
    - "4 AM – 7 PM" → hours 4..18
    - "9 PM – 4 AM" → hours 21..23, 0..3 (midnight wrap)
    - "9 AM – 4 PM; 9 PM – 4 AM" → union of both ranges
  """
  def parse_time_ranges("All day"), do: MapSet.new(0..23)

  def parse_time_ranges(time_str) do
    time_str
    |> String.split(~r/[;&]/)
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(&parse_single_range/1)
    |> MapSet.new()
  end

  defp parse_single_range(range_str) do
    case String.split(range_str, ~r/\s*[\x{2013}\x{2014}\-]+\s*/u) do
      [start_str, end_str] ->
        start_hour = parse_hour(start_str)
        end_hour = parse_hour(end_str)

        if start_hour <= end_hour do
          # Normal range: 4 AM (4) to 7 PM (19) → 4..18
          Enum.to_list(start_hour..(end_hour - 1))
        else
          # Midnight wrap: 9 PM (21) to 4 AM (4) → 21..23, 0..3
          Enum.to_list(start_hour..23) ++ Enum.to_list(0..(end_hour - 1))
        end

      _ ->
        []
    end
  end

  @doc """
  Parses an hour string like "4 AM", "9 PM", "12 AM", "12 PM" into 0-23.
  """
  def parse_hour(str) do
    str = String.trim(str)

    case Regex.run(~r/(\d+)\s*(AM|PM|am|pm)/i, str) do
      [_, hour_str, period] ->
        hour = String.to_integer(hour_str)
        period = String.upcase(period)

        cond do
          period == "AM" and hour == 12 -> 0
          period == "PM" and hour == 12 -> 12
          period == "PM" -> hour + 12
          true -> hour
        end

      _ ->
        0
    end
  end

  @doc """
  Formats a list of hours into a human-readable time range.

  Groups consecutive hours and returns the longest consecutive run
  as "X:00 AM/PM - Y:00 AM/PM".
  """
  def format_time_range(hours) do
    chunks =
      hours
      |> Enum.sort()
      |> chunk_consecutive()

    chunk = Enum.max_by(chunks, &length/1)
    start_hour = hd(chunk)
    end_hour = rem(List.last(chunk) + 1, 24)
    "#{format_hour(start_hour)} - #{format_hour(end_hour)}"
  end

  defp chunk_consecutive([]), do: [[]]

  defp chunk_consecutive([first | rest]) do
    chunks =
      Enum.reduce(rest, [[first]], fn hour, [current | groups] ->
        if hour == List.last(current) + 1 do
          [current ++ [hour] | groups]
        else
          [[hour] | [current | groups]]
        end
      end)
      |> Enum.reverse()

    # Join first and last chunks if they wrap around midnight (23 → 0)
    case chunks do
      [first_chunk | middle] when length(chunks) > 1 ->
        last_chunk = List.last(middle)
        rest_middle = Enum.drop(middle, -1)

        if List.last(last_chunk) == 23 and hd(first_chunk) == 0 do
          merged = last_chunk ++ first_chunk
          [merged | rest_middle]
        else
          chunks
        end

      _ ->
        chunks
    end
  end

  defp format_hour(0), do: "12:00 AM"
  defp format_hour(12), do: "12:00 PM"

  defp format_hour(hour) when hour < 12 do
    "#{hour}:00 AM"
  end

  defp format_hour(hour) do
    "#{hour - 12}:00 PM"
  end
end

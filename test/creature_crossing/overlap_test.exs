defmodule CreatureCrossing.OverlapTest do
  use ExUnit.Case, async: true

  alias CreatureCrossing.Overlap

  describe "parse_hour/1" do
    test "parses AM hours" do
      assert Overlap.parse_hour("4 AM") == 4
      assert Overlap.parse_hour("9 AM") == 9
      assert Overlap.parse_hour("11 AM") == 11
    end

    test "parses PM hours" do
      assert Overlap.parse_hour("1 PM") == 13
      assert Overlap.parse_hour("7 PM") == 19
      assert Overlap.parse_hour("11 PM") == 23
    end

    test "handles 12 AM (midnight) and 12 PM (noon)" do
      assert Overlap.parse_hour("12 AM") == 0
      assert Overlap.parse_hour("12 PM") == 12
    end
  end

  describe "parse_time_ranges/1" do
    test "parses 'All day' to all 24 hours" do
      result = Overlap.parse_time_ranges("All day")
      assert MapSet.size(result) == 24
      assert MapSet.member?(result, 0)
      assert MapSet.member?(result, 23)
    end

    test "parses normal daytime range" do
      result = Overlap.parse_time_ranges("4 AM – 7 PM")
      # 4 AM to 7 PM = hours 4..18 (15 hours)
      assert MapSet.size(result) == 15
      assert MapSet.member?(result, 4)
      assert MapSet.member?(result, 18)
      refute MapSet.member?(result, 19)
      refute MapSet.member?(result, 3)
    end

    test "parses midnight-wrapping range" do
      result = Overlap.parse_time_ranges("9 PM – 4 AM")
      # 9 PM to 4 AM = hours 21, 22, 23, 0, 1, 2, 3 (7 hours)
      assert MapSet.size(result) == 7
      assert MapSet.member?(result, 21)
      assert MapSet.member?(result, 23)
      assert MapSet.member?(result, 0)
      assert MapSet.member?(result, 3)
      refute MapSet.member?(result, 4)
      refute MapSet.member?(result, 20)
    end

    test "parses multi-window ranges separated by semicolon" do
      result = Overlap.parse_time_ranges("9 AM – 4 PM; 9 PM – 4 AM")
      # 9 AM–4 PM = 9..15 (7 hours) + 9 PM–4 AM = 21..23, 0..3 (7 hours) = 14 total
      assert MapSet.size(result) == 14
      assert MapSet.member?(result, 9)
      assert MapSet.member?(result, 15)
      assert MapSet.member?(result, 21)
      assert MapSet.member?(result, 0)
    end
  end

  describe "format_time_range/1" do
    test "formats a single hour" do
      assert Overlap.format_time_range([14]) == "2:00 PM - 3:00 PM"
    end

    test "formats consecutive hours" do
      assert Overlap.format_time_range([13, 14, 15]) == "1:00 PM - 4:00 PM"
    end

    test "formats midnight-area hours" do
      assert Overlap.format_time_range([0]) == "12:00 AM - 1:00 AM"
    end

    test "formats noon" do
      assert Overlap.format_time_range([12]) == "12:00 PM - 1:00 PM"
    end

    test "picks longest consecutive run when hours are non-consecutive" do
      # Two runs: [2,3,4] (length 3) and [20,21] (length 2) → picks 2-5
      assert Overlap.format_time_range([2, 3, 4, 20, 21]) == "2:00 AM - 5:00 AM"
    end
  end

  describe "calculate/2" do
    test "finds the best overlap month and time" do
      # Two critters available in January, 4 AM – 7 PM
      critters = [
        critter("Bug A", [1, 2, 3], "4 AM – 7 PM"),
        critter("Bug B", [1, 2], "9 AM – 5 PM")
      ]

      result = Overlap.calculate(critters, "north")
      assert result.month == "January"
      assert result.critter_count == 2
      assert length(result.critters) == 2
      # Overlap is 9 AM – 5 PM (both available)
      assert result.time_range == "9:00 AM - 5:00 PM"
    end

    test "handles critters with midnight-wrapping times" do
      critters = [
        critter("Night Bug", [6], "9 PM – 4 AM"),
        critter("All Day Bug", [6], "All day")
      ]

      result = Overlap.calculate(critters, "north")
      assert result.month == "June"
      assert result.critter_count == 2
      # Both overlap during 9 PM – 4 AM
      assert result.time_range == "9:00 PM - 4:00 AM"
    end

    test "handles 'All day' critters" do
      critters = [
        critter("All Day A", [3], "All day"),
        critter("All Day B", [3], "All day")
      ]

      result = Overlap.calculate(critters, "north")
      assert result.month == "March"
      assert result.critter_count == 2
    end

    test "returns no overlap when no critters provided" do
      result = Overlap.calculate([], "north")
      assert result.month == nil
      assert result.time_range == "No Overlap"
      assert result.critter_count == 0
      assert result.critters == []
    end

    test "uses south hemisphere data when specified" do
      critters = [
        %{
          "name" => "Southern Bug",
          "image_url" => "img.png",
          "north" => %{
            "months_array" => [],
            "times_by_month" => %{}
          },
          "south" => %{
            "months_array" => [7],
            "times_by_month" => %{"7" => "All day"}
          }
        }
      ]

      result = Overlap.calculate(critters, "south")
      assert result.month == "July"
      assert result.critter_count == 1
    end

    test "picks month with highest overlap count" do
      critters = [
        critter("Bug A", [1, 6], "All day"),
        critter("Bug B", [6], "All day"),
        critter("Bug C", [6], "All day")
      ]

      result = Overlap.calculate(critters, "north")
      # June has 3 critters, January only 1
      assert result.month == "June"
      assert result.critter_count == 3
    end
  end

  # Helper to build a critter map with north hemisphere data
  defp critter(name, months, time) do
    %{
      "name" => name,
      "image_url" => "https://example.com/#{name}.png",
      "location" => "Flying",
      "rarity" => "Common",
      "north" => %{
        "months_array" => months,
        "times_by_month" => Map.new(months, fn m -> {to_string(m), time} end)
      },
      "south" => %{
        "months_array" => [],
        "times_by_month" => %{}
      }
    }
  end
end

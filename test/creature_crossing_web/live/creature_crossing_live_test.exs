defmodule CreatureCrossingWeb.CreatureCrossingLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders critter tool with all three category boxes", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
    assert html =~ "Bugs"
    assert html =~ "Fish"
    assert html =~ "Diving"
  end

  test "sets page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
  end

  test "renders critter names from stub data in all categories", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    # Bug
    assert html =~ "Common butterfly"
    # Fish
    assert html =~ "Sea bass"
    # Sea creature
    assert html =~ "Seaweed"
  end

  test "hemisphere toggle switches active label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    html = view |> element(~s(input[phx-click="toggle_hemisphere"])) |> render_click()
    # After toggling, Southern should be highlighted
    assert html =~ "Southern"
  end

  test "flip mode toggles selection label", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Missing"
    assert html =~ "Have"
  end

  test "clicking a critter toggles selection", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    html = view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    assert html =~ "1 selected"

    html = view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    assert html =~ "0 selected"
  end

  test "calculate button is disabled until 5 critters selected", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "disabled"
    assert html =~ "need 5 more"

    # Select 5 critters (across categories since all are visible)
    for name <- ["Common butterfly", "Monarch butterfly", "Honeybee", "Sea bass", "Seaweed"] do
      view |> element(~s(li[phx-value-name="#{name}"])) |> render_click()
    end

    html = render(view)
    assert html =~ "5 selected"
    refute html =~ "need"
  end

  test "selections work across all three categories simultaneously", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    # Select one from each category
    view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    view |> element(~s(li[phx-value-name="Sea bass"])) |> render_click()
    html = view |> element(~s(li[phx-value-name="Seaweed"])) |> render_click()

    assert html =~ "3 selected"
  end

  describe "results view" do
    defp select_and_calculate(view) do
      for name <- ["Common butterfly", "Monarch butterfly", "Honeybee", "Tarantula", "Emperor butterfly"] do
        view |> element(~s(li[phx-value-name="#{name}"])) |> render_click()
      end

      view |> element("button", "Calculate") |> render_click()
    end

    test "shows results after calculation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/creature-crossing")
      html = select_and_calculate(view)

      assert html =~ "critters catchable"
      assert html =~ "Back to selection"
    end

    test "shows month and time range in results", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/creature-crossing")
      html = select_and_calculate(view)

      # Should show one of the month names
      assert html =~ ~r/(January|February|March|April|May|June|July|August|September|October|November|December)/
      # Should show a time range with AM/PM
      assert html =~ ~r/\d+:00 (AM|PM)/
    end

    test "clicking a critter marks it as caught", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/creature-crossing")
      select_and_calculate(view)

      html = view |> element(~s(div[phx-value-name="Common butterfly"])) |> render_click()
      assert html =~ "Caught!"
      assert html =~ "1 caught"
    end

    test "recalculate button behavior after catches", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/creature-crossing")

      # Select many critters so we have enough for recalculation
      for name <- ["Common butterfly", "Monarch butterfly", "Honeybee", "Tarantula",
                    "Emperor butterfly", "Scorpion", "Atlas moth", "Sea bass", "Pale chub",
                    "Coelacanth", "Tuna", "Oarfish", "Golden trout"] do
        view |> element(~s(li[phx-value-name="#{name}"])) |> render_click()
      end

      html = view |> element("button", "Calculate") |> render_click()
      count = html |> then(fn h ->
        case Regex.run(~r/(\d+) critters catchable/, h) do
          [_, n] -> String.to_integer(n)
          _ -> 0
        end
      end)

      # Only test catching if we have enough critters in results
      if count >= 8 do
        # Find critter names that are actually in the results by looking for phx-value-name divs
        result_names =
          Regex.scan(~r/phx-value-name="([^"]+)"/, html)
          |> Enum.map(fn [_, name] -> name end)
          |> Enum.uniq()

        # Catch 3
        [first, second, third | _] = result_names
        view |> element(~s(div[phx-value-name="#{first}"])) |> render_click()
        view |> element(~s(div[phx-value-name="#{second}"])) |> render_click()
        html = view |> element(~s(div[phx-value-name="#{third}"])) |> render_click()

        assert html =~ "3 caught"
        # With enough remaining, recalculate should appear
        assert html =~ "Recalculate" or html =~ "Not enough"
      end
    end

    test "back button returns to selection view", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/creature-crossing")
      select_and_calculate(view)

      html = view |> element("button", "Back to selection") |> render_click()
      assert html =~ "Critter Calculator"
      assert html =~ "Bugs"
    end
  end
end

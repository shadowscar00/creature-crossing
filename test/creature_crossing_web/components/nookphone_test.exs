defmodule CreatureCrossingWeb.Components.NookphoneTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias CreatureCrossingWeb.Components.Nookphone

  describe "nookphone/1" do
    test "renders the nookphone button" do
      html = render_component(&Nookphone.nookphone/1, current_path: "/")
      assert html =~ "nookphone-btn"
      assert html =~ "Open Nookphone menu"
    end

    test "renders the modal overlay (hidden by default)" do
      html = render_component(&Nookphone.nookphone/1, current_path: "/")
      assert html =~ "nookphone-overlay"
      assert html =~ "NookPhone"
    end

    test "renders all four app buttons" do
      html = render_component(&Nookphone.nookphone/1, current_path: "/")
      assert html =~ "Critter Tool"
      assert html =~ "Home"
      assert html =~ "Guess Who"
      assert html =~ "Match Game"
    end

    test "renders correct navigation links" do
      html = render_component(&Nookphone.nookphone/1, current_path: "/")
      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/creature-crossing")
      assert html =~ ~s(href="/guess-who")
      assert html =~ ~s(href="/match-game")
    end

    test "highlights the active app based on current_path" do
      html = render_component(&Nookphone.nookphone/1, current_path: "/creature-crossing")
      # The active app should have the primary styling
      assert html =~ "bg-primary"
    end
  end
end

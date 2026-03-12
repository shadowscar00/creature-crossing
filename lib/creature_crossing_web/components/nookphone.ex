defmodule CreatureCrossingWeb.Components.Nookphone do
  @moduledoc """
  Nookphone navigation component.

  Renders a Nookphone icon button that opens a styled modal with
  app buttons for each tool/game, mimicking the in-game Nookphone UI.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders the Nookphone button and navigation modal.

  The button sits in the navbar. Clicking it opens a modal overlay
  with a grid of app buttons. Clicking an app navigates to its route.
  Close via outside-click, Escape key, or the X button.
  """
  attr :current_path, :string, default: "/", doc: "the current page path for highlighting"

  def nookphone(assigns) do
    ~H"""
    <button
      id="nookphone-btn"
      phx-click={open_nookphone()}
      class="btn btn-circle btn-ghost hover:bg-primary-content/20 transition-transform hover:scale-110"
      aria-label="Open Nookphone menu"
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-7">
        <path
          fill-rule="evenodd"
          d="M7.5 2.25A2.25 2.25 0 0 0 5.25 4.5v15a2.25 2.25 0 0 0 2.25 2.25h9a2.25 2.25 0 0 0 2.25-2.25v-15A2.25 2.25 0 0 0 16.5 2.25h-9Zm3.75 15a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Z"
          clip-rule="evenodd"
        />
      </svg>
    </button>

    <div
      id="nookphone-overlay"
      class="fixed inset-0 z-50 hidden"
      phx-window-keydown={close_nookphone()}
      phx-key="Escape"
    >
      <%!-- Backdrop — clicking it closes the modal --%>
      <div
        id="nookphone-backdrop"
        class="absolute inset-0 bg-black/40 transition-opacity duration-300 opacity-0"
      />

      <%!-- Centering container — clicks here (outside modal) close it --%>
      <div
        id="nookphone-clickaway"
        phx-click={close_nookphone()}
        class="absolute inset-0 flex items-center justify-center p-4"
      >
        <%!-- Phone modal — stop click propagation so clicking inside doesn't close --%>
        <div
          id="nookphone-modal"
          onclick="event.stopPropagation()"
          class="relative bg-accent/90 rounded-3xl shadow-2xl p-6 w-56 h-96
                 border-[6px] border-neutral/80 transform transition-all duration-300
                 scale-75 opacity-0 flex flex-col"
        >
          <%!-- Close button --%>
          <button
            phx-click={close_nookphone()}
            class="absolute top-2 right-3 text-accent-content/60 hover:text-accent-content
                   cursor-pointer transition-colors"
            aria-label="Close Nookphone"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-5">
              <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
            </svg>
          </button>

          <%!-- Header --%>
          <h2 class="text-accent-content font-extrabold text-lg mb-4">
            NookPhone
          </h2>

          <%!-- App grid --%>
          <div class="grid grid-cols-2 grid-rows-3 gap-3 flex-1">
            <.nookphone_app
              href="/"
              label="Home"
              current_path={@current_path}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-8">
                <path d="M11.47 3.841a.75.75 0 0 1 1.06 0l8.69 8.69a.75.75 0 1 0 1.06-1.061l-8.689-8.69a2.25 2.25 0 0 0-3.182 0l-8.69 8.69a.75.75 0 1 0 1.061 1.06l8.69-8.689Z" />
                <path d="m12 5.432 8.159 8.159c.03.03.06.058.091.086v6.198c0 1.035-.84 1.875-1.875 1.875H15a.75.75 0 0 1-.75-.75v-4.5a.75.75 0 0 0-.75-.75h-3a.75.75 0 0 0-.75.75V21a.75.75 0 0 1-.75.75H5.625a1.875 1.875 0 0 1-1.875-1.875v-6.198a2.29 2.29 0 0 0 .091-.086L12 5.432Z" />
              </svg>
            </.nookphone_app>

            <.nookphone_app
              href="/creature-crossing"
              label="Critter Tool"
              current_path={@current_path}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-8">
                <path d="M12 2.25a.75.75 0 0 1 .75.75v.756a49.106 49.106 0 0 1 9.152 1 .75.75 0 0 1-.152 1.485h-1.918l2.474 10.124a.75.75 0 0 1-.375.84A6.723 6.723 0 0 1 18.75 18a6.723 6.723 0 0 1-3.181-.795.75.75 0 0 1-.375-.84l2.474-10.124H12.75v13.28c1.293.076 2.534.343 3.697.776a.75.75 0 0 1-.262 1.453h-8.37a.75.75 0 0 1-.262-1.453c1.162-.433 2.404-.7 3.697-.776V6.24H6.332l2.474 10.124a.75.75 0 0 1-.375.84A6.723 6.723 0 0 1 5.25 18a6.723 6.723 0 0 1-3.181-.795.75.75 0 0 1-.375-.84L4.168 6.241H2.25a.75.75 0 0 1-.152-1.485 49.105 49.105 0 0 1 9.152-1V3a.75.75 0 0 1 .75-.75Z" />
              </svg>
            </.nookphone_app>

            <.nookphone_app
              href="/guess-who"
              label="Guess Who"
              current_path={@current_path}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-8">
                <path d="M9.315 7.584C12.195 3.883 16.695 1.5 21.75 1.5a.75.75 0 0 1 .75.75c0 5.056-2.383 9.555-6.084 12.436A6.75 6.75 0 0 1 9.75 22.5a.75.75 0 0 1-.75-.75v-4.131A15.838 15.838 0 0 1 6.382 15H2.25a.75.75 0 0 1-.75-.75 6.75 6.75 0 0 1 7.815-6.666ZM15 6.75a2.25 2.25 0 1 0 0 4.5 2.25 2.25 0 0 0 0-4.5Z" />
              </svg>
            </.nookphone_app>

            <.nookphone_app
              href="/match-game"
              label="Match Game"
              current_path={@current_path}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-8">
                <path d="M11.644 1.59a.75.75 0 0 1 .712 0l9.75 5.25a.75.75 0 0 1 0 1.32l-9.75 5.25a.75.75 0 0 1-.712 0l-9.75-5.25a.75.75 0 0 1 0-1.32l9.75-5.25Z" />
                <path d="m3.265 10.602 7.668 4.129a2.25 2.25 0 0 0 2.134 0l7.668-4.13 1.37.739a.75.75 0 0 1 0 1.32l-9.75 5.25a.75.75 0 0 1-.71 0l-9.75-5.25a.75.75 0 0 1 0-1.32l1.37-.738Z" />
                <path d="m10.933 19.231-7.668-4.13-1.37.739a.75.75 0 0 0 0 1.32l9.75 5.25c.221.12.489.12.71 0l9.75-5.25a.75.75 0 0 0 0-1.32l-1.37-.738-7.668 4.13a2.25 2.25 0 0 1-2.134-.001Z" />
              </svg>
            </.nookphone_app>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :current_path, :string, default: "/"
  slot :inner_block, required: true

  defp nookphone_app(assigns) do
    active = assigns.current_path == assigns.href
    assigns = Phoenix.Component.assign(assigns, :active, active)

    ~H"""
    <a
      href={@href}
      class={[
        "flex flex-col items-center gap-1.5 p-3 rounded-2xl transition-all",
        "hover:scale-105 hover:shadow-md",
        @active && "bg-primary text-primary-content shadow-md",
        !@active && "bg-base-100/80 text-base-content hover:bg-base-100"
      ]}
    >
      {render_slot(@inner_block)}
      <span class="text-xs font-bold">{@label}</span>
    </a>
    """
  end

  defp open_nookphone do
    JS.show(to: "#nookphone-overlay")
    |> JS.transition(
      {"transition-opacity duration-300", "opacity-0", "opacity-100"},
      to: "#nookphone-backdrop"
    )
    |> JS.transition(
      {"transition-all duration-300", "scale-75 opacity-0", "scale-100 opacity-100"},
      to: "#nookphone-modal"
    )
    |> JS.focus_first(to: "#nookphone-modal")
  end

  defp close_nookphone do
    JS.transition(
      {"transition-opacity duration-200", "opacity-100", "opacity-0"},
      to: "#nookphone-backdrop"
    )
    |> JS.transition(
      {"transition-all duration-200", "scale-100 opacity-100", "scale-75 opacity-0"},
      to: "#nookphone-modal"
    )
    |> JS.hide(to: "#nookphone-overlay", transition: {"", "", ""}, time: 200)
    |> JS.focus(to: "#nookphone-btn")
  end
end

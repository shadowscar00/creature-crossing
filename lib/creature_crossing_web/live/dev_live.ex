defmodule CreatureCrossingWeb.DevLive do
  @moduledoc """
  Dev tool page showing villagers with missing data or placeholder images.
  Password-protected with a server-side check.
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Repo
  alias CreatureCrossing.Data.Villager
  import Ecto.Query

  @placeholder "/images/critter_placeholder.svg"
  # Password is checked server-side only — never sent to client
  @password_hash :crypto.hash(:sha256, "horsedev")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dev Tools",
       authenticated: false,
       attempts: 0,
       password_error: nil,
       villagers: []
     )}
  end

  @impl true
  def handle_event("check_password", %{"password" => password}, socket) do
    input_hash = :crypto.hash(:sha256, password)

    if input_hash == @password_hash do
      villagers = load_problem_villagers()

      {:noreply,
       assign(socket,
         authenticated: true,
         password_error: nil,
         villagers: villagers
       )}
    else
      attempts = socket.assigns.attempts + 1

      if attempts >= 3 do
        {:noreply, push_navigate(socket, to: "/")}
      else
        {:noreply,
         assign(socket,
           attempts: attempts,
           password_error: "Wrong password. #{3 - attempts} attempt(s) remaining."
         )}
      end
    end
  end

  defp load_problem_villagers do
    Repo.all(
      from v in Villager,
        where:
          v.icon_url == ^@placeholder or
            v.poster_url == ^@placeholder or
            v.amiibo_url == ^@placeholder or
            v.personality == "Unknown" or
            v.hobby == "Unknown" or
            v.species == "Unknown" or
            v.sign == "Unknown" or
            v.fav_colors == "[]" or
            v.fav_styles == "[]",
        order_by: v.name
    )
    |> Enum.map(fn v ->
      problems =
        []
        |> then(fn p -> if v.icon_url == @placeholder, do: ["icon"] ++ p, else: p end)
        |> then(fn p -> if v.poster_url == @placeholder, do: ["poster"] ++ p, else: p end)
        |> then(fn p -> if v.amiibo_url == @placeholder, do: ["amiibo"] ++ p, else: p end)
        |> then(fn p -> if v.personality == "Unknown", do: ["personality"] ++ p, else: p end)
        |> then(fn p -> if v.hobby == "Unknown", do: ["hobby"] ++ p, else: p end)
        |> then(fn p -> if v.species == "Unknown", do: ["species"] ++ p, else: p end)
        |> then(fn p -> if v.sign == "Unknown", do: ["sign"] ++ p, else: p end)
        |> then(fn p -> if v.fav_colors == "[]", do: ["colors"] ++ p, else: p end)
        |> then(fn p -> if v.fav_styles == "[]", do: ["styles"] ++ p, else: p end)

      %{villager: v, problems: problems}
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto px-4" style="padding-top: 0.25rem; max-width: 72rem;">
      <h1 style="font-size: 2rem; margin-bottom: 1rem;" class="font-extrabold tracking-tight text-center">
        Dev Tools
      </h1>

      <%!-- Password modal --%>
      <div :if={!@authenticated} style="position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 50;">
        <div style="background: var(--color-base-100); border: 2px solid var(--color-neutral); border-radius: 1rem; padding: 2rem; text-align: center; max-width: 20rem; width: 90%;">
          <p style="font-weight: 700; font-size: 1.1rem; margin-bottom: 1rem;">Enter Dev Password</p>
          <form phx-submit="check_password">
            <input
              type="password"
              name="password"
              placeholder="Password"
              class="input input-bordered w-full"
              style="margin-bottom: 0.75rem;"
              autofocus
            />
            <p :if={@password_error} style="color: var(--color-error); font-size: 0.8rem; margin-bottom: 0.75rem;">
              {@password_error}
            </p>
            <button type="submit" class="btn btn-primary btn-wide">Enter</button>
          </form>
        </div>
      </div>

      <%!-- Content (disabled until authenticated) --%>
      <div style={"#{if !@authenticated, do: "filter: blur(4px); pointer-events: none;", else: ""}"}>
        <p style="margin-bottom: 1rem; opacity: 0.7; text-align: center;">
          {length(@villagers)} villager(s) with missing or placeholder data
        </p>

        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr)); gap: 0.75rem;">
          <div :for={entry <- @villagers} style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
            <div style="padding: 0.75rem; text-align: center; background: color-mix(in oklch, var(--color-primary) 10%, transparent);">
              <img
                src={entry.villager.icon_url}
                alt=""
                style="width: 3.5rem; height: 3.5rem; object-fit: contain; margin: 0 auto 0.25rem auto; display: block;"
                loading="lazy"
                onerror="this.style.display='none'"
              />
              <p class="text-primary" style="font-weight: 700; font-size: 0.9rem;">{entry.villager.name}</p>
              <div style="font-size: 0.7rem; opacity: 0.7; margin-top: 0.25rem; text-align: left;">
                <p><strong>Species:</strong> {entry.villager.species}</p>
                <p><strong>Personality:</strong> {entry.villager.personality}</p>
                <p><strong>Gender:</strong> {entry.villager.gender}</p>
                <p><strong>Sign:</strong> {entry.villager.sign}</p>
                <p><strong>Hobby:</strong> {entry.villager.hobby}</p>
                <p><strong>Colors:</strong> {entry.villager.fav_colors}</p>
                <p><strong>Styles:</strong> {entry.villager.fav_styles}</p>
                <p><strong>Icon:</strong> {if entry.villager.icon_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
                <p><strong>Poster:</strong> {if entry.villager.poster_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
                <p><strong>Amiibo:</strong> {if entry.villager.amiibo_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
              </div>
              <div style="margin-top: 0.5rem; display: flex; flex-wrap: wrap; gap: 0.25rem; justify-content: center;">
                <span
                  :for={problem <- entry.problems}
                  style="font-size: 0.6rem; padding: 0.125rem 0.375rem; border-radius: 0.25rem; background: var(--color-error); color: var(--color-error-content); font-weight: 600;"
                >
                  {problem}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

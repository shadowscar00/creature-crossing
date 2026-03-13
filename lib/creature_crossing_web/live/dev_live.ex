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
  # Password is read from .dev_password at compile time — file is gitignored
  @password_hash :crypto.hash(
                   :sha256,
                   ".dev_password" |> File.read!() |> String.trim()
                 )

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dev Tools",
       authenticated: false,
       attempts: 0,
       password_error: nil,
       villagers: [],
       duplicates: %{}
     )}
  end

  @impl true
  def handle_event("check_password", %{"password" => password}, socket) do
    input_hash = :crypto.hash(:sha256, password)

    if input_hash == @password_hash do
      {:noreply,
       assign(socket,
         authenticated: true,
         password_error: nil,
         villagers: load_problem_villagers()
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

  @impl true
  def handle_event("check_duplicates", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    villager = Repo.get!(Villager, id)

    # Search for potential duplicates by name words or same icon
    name_words =
      villager.name
      |> String.split(~r/[\s.]+/)
      |> Enum.reject(&(&1 == ""))

    name_conditions =
      Enum.reduce(name_words, dynamic(false), fn word, acc ->
        pattern = "%#{word}%"
        dynamic([v], ^acc or like(v.name, ^pattern))
      end)

    matches =
      Repo.all(
        from v in Villager,
          where: ^name_conditions or (v.icon_url == ^villager.icon_url and v.icon_url != ^@placeholder),
          where: v.id != ^id,
          order_by: v.name
      )

    duplicates = Map.put(socket.assigns.duplicates, id, matches)
    {:noreply, assign(socket, duplicates: duplicates)}
  end

  @impl true
  def handle_event("accept_villager", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    villager = Repo.get!(Villager, id)
    Repo.update!(Ecto.Changeset.change(villager, role: "villager"))

    {:noreply, assign(socket, villagers: load_problem_villagers())}
  end

  @impl true
  def handle_event("accept_character", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    villager = Repo.get!(Villager, id)
    Repo.update!(Ecto.Changeset.change(villager, role: "character"))

    {:noreply, assign(socket, villagers: load_problem_villagers())}
  end

  @impl true
  def handle_event("delete_villager", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    villager = Repo.get!(Villager, id)
    Repo.delete!(villager)

    duplicates = Map.delete(socket.assigns.duplicates, id)
    {:noreply, assign(socket, villagers: load_problem_villagers(), duplicates: duplicates)}
  end

  defp load_problem_villagers do
    Repo.all(
      from v in Villager,
        where: v.role == "unclassified",
        order_by: v.name
    )
    |> Enum.map(fn v ->
      problems =
        []
        |> maybe_add(v.icon_url == @placeholder, "icon")
        |> maybe_add(v.poster_url == @placeholder, "poster")
        |> maybe_add(v.amiibo_url == @placeholder, "amiibo")
        |> maybe_add(v.personality == "Unknown", "personality")
        |> maybe_add(v.hobby == "Unknown", "hobby")
        |> maybe_add(v.species == "Unknown", "species")
        |> maybe_add(v.sign == "Unknown", "sign")
        |> maybe_add(v.fav_colors == "[]", "colors")
        |> maybe_add(v.fav_styles == "[]", "styles")
        |> maybe_add(v.role == "unclassified", "unclassified")

      %{villager: v, problems: problems}
    end)
  end

  defp maybe_add(list, true, label), do: [label | list]
  defp maybe_add(list, false, _label), do: list

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
          <div :for={entry <- @villagers} style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden; display: flex; flex-direction: column;">
            <div style="padding: 0.75rem; text-align: center; background: color-mix(in oklch, var(--color-primary) 10%, transparent); flex: 1;">
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
                <p><strong>Role:</strong> {entry.villager.role}</p>
                <p><strong>Icon:</strong> {if entry.villager.icon_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
                <p><strong>Poster:</strong> {if entry.villager.poster_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
                <p><strong>Amiibo:</strong> {if entry.villager.amiibo_url == "/images/critter_placeholder.svg", do: "MISSING", else: "OK"}</p>
              </div>

              <%!-- Problem tags --%>
              <div style="margin-top: 0.5rem; display: flex; flex-wrap: wrap; gap: 0.25rem; justify-content: center;">
                <span
                  :for={problem <- entry.problems}
                  style={"font-size: 0.6rem; padding: 0.125rem 0.375rem; border-radius: 0.25rem; font-weight: 600; #{if problem == "unclassified", do: "background: var(--color-warning); color: var(--color-warning-content);", else: "background: var(--color-error); color: var(--color-error-content);"}"}
                >
                  {problem}
                </span>
              </div>

              <%!-- Duplicate results --%>
              <div :if={Map.has_key?(@duplicates, entry.villager.id)} style="margin-top: 0.5rem; text-align: left; font-size: 0.65rem; border-top: 1px solid var(--color-neutral); padding-top: 0.375rem;">
                <p :if={@duplicates[entry.villager.id] == []} style="opacity: 0.5;">No duplicates found</p>
                <div :for={dup <- @duplicates[entry.villager.id]} style="padding: 0.25rem 0; border-bottom: 1px solid color-mix(in oklch, var(--color-neutral) 30%, transparent);">
                  <p><strong>{dup.name}</strong> ({dup.role || "unclassified"})</p>
                  <p style="opacity: 0.6;">{dup.species} · {dup.personality} · {dup.hobby}</p>
                </div>
              </div>
            </div>

            <%!-- Action buttons --%>
            <div style="display: grid; grid-template-columns: 1fr 1fr; border-top: 2px solid var(--color-neutral);">
              <button
                phx-click="check_duplicates"
                phx-value-id={entry.villager.id}
                style="padding: 0.375rem; font-size: 0.6rem; font-weight: 600; border-right: 1px solid var(--color-neutral); border-bottom: 1px solid var(--color-neutral); background: color-mix(in oklch, var(--color-info) 15%, transparent); cursor: pointer;"
              >
                Check Dupes
              </button>
              <button
                phx-click="accept_villager"
                phx-value-id={entry.villager.id}
                style="padding: 0.375rem; font-size: 0.6rem; font-weight: 600; border-bottom: 1px solid var(--color-neutral); background: color-mix(in oklch, var(--color-success) 15%, transparent); cursor: pointer;"
              >
                Accept Villager
              </button>
              <button
                phx-click="accept_character"
                phx-value-id={entry.villager.id}
                style="padding: 0.375rem; font-size: 0.6rem; font-weight: 600; border-right: 1px solid var(--color-neutral); background: color-mix(in oklch, var(--color-warning) 15%, transparent); cursor: pointer;"
              >
                Accept Character
              </button>
              <button
                phx-click="delete_villager"
                phx-value-id={entry.villager.id}
                data-confirm={"Delete #{entry.villager.name}? This cannot be undone."}
                style="padding: 0.375rem; font-size: 0.6rem; font-weight: 600; background: color-mix(in oklch, var(--color-error) 15%, transparent); cursor: pointer;"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

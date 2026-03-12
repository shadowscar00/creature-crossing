defmodule CreatureCrossing.Nookipedia.Live do
  @moduledoc """
  Live HTTP client for the Nookipedia API.

  Requires API key configured as:

      config :creature_crossing, :nookipedia_api_key, "your-key-here"
  """
  @behaviour CreatureCrossing.Nookipedia

  @base_url "https://api.nookipedia.com"

  @impl true
  def list_bugs, do: get("/nh/bugs")

  @impl true
  def list_fish, do: get("/nh/fish")

  @impl true
  def list_sea_creatures, do: get("/nh/sea")

  @impl true
  def list_villagers, do: get("/villagers", nhdetails: "true", game: "nh")

  @impl true
  def list_items(category) when category in ~w(furniture clothing art fossils) do
    get("/nh/#{category}")
  end

  defp get(path, params \\ []) do
    api_key = Application.fetch_env!(:creature_crossing, :nookipedia_api_key)

    case Req.get("#{@base_url}#{path}",
           params: params,
           headers: [{"X-API-KEY", api_key}, {"Accept-Version", "2.0.0"}]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

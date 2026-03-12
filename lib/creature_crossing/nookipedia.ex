defmodule CreatureCrossing.Nookipedia do
  @moduledoc """
  Nookipedia API client interface.

  Delegates to either the live HTTP client or the stub client
  based on application config:

      config :creature_crossing, :nookipedia_client, CreatureCrossing.Nookipedia.Stub
  """

  @type critter :: %{
          name: String.t(),
          image_url: String.t(),
          number: integer(),
          location: String.t(),
          rarity: String.t(),
          sell_nook: integer(),
          north: hemisphere_data(),
          south: hemisphere_data()
        }

  @type hemisphere_data :: %{
          availability_array: [%{months: String.t(), time: String.t()}],
          months_array: [integer()],
          times_by_month: %{String.t() => String.t()}
        }

  @type villager :: %{
          name: String.t(),
          image_url: String.t(),
          species: String.t(),
          personality: String.t(),
          gender: String.t(),
          birthday_month: String.t(),
          birthday_day: String.t(),
          sign: String.t(),
          hobby: String.t(),
          fav_colors: [String.t()],
          fav_styles: [String.t()]
        }

  @type item :: %{
          name: String.t(),
          image_url: String.t()
        }

  @callback list_bugs() :: {:ok, [critter()]} | {:error, term()}
  @callback list_fish() :: {:ok, [critter()]} | {:error, term()}
  @callback list_sea_creatures() :: {:ok, [critter()]} | {:error, term()}
  @callback list_villagers() :: {:ok, [villager()]} | {:error, term()}
  @callback list_items(category :: String.t()) :: {:ok, [item()]} | {:error, term()}

  defp client, do: Application.get_env(:creature_crossing, :nookipedia_client, __MODULE__.Stub)

  def list_bugs, do: client().list_bugs()
  def list_fish, do: client().list_fish()
  def list_sea_creatures, do: client().list_sea_creatures()
  def list_villagers, do: client().list_villagers()
  def list_items(category), do: client().list_items(category)
end

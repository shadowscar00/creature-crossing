defmodule CreatureCrossing.Nookipedia.Db do
  @moduledoc """
  Database-backed Nookipedia client. Queries the local SQLite database
  and returns data in the same format as the Stub.
  """
  @behaviour CreatureCrossing.Nookipedia

  import Ecto.Query

  alias CreatureCrossing.Repo
  alias CreatureCrossing.Data.{Critter, Villager, Item}

  @impl true
  def list_bugs do
    critters = Repo.all(from c in Critter, where: c.type == "bug", order_by: c.name)
    {:ok, Enum.map(critters, &Critter.to_api_map/1)}
  end

  @impl true
  def list_fish do
    critters = Repo.all(from c in Critter, where: c.type == "fish", order_by: c.name)
    {:ok, Enum.map(critters, &Critter.to_api_map/1)}
  end

  @impl true
  def list_sea_creatures do
    critters = Repo.all(from c in Critter, where: c.type == "sea", order_by: c.name)
    {:ok, Enum.map(critters, &Critter.to_api_map/1)}
  end

  @impl true
  def list_villagers do
    villagers = Repo.all(from v in Villager, order_by: v.name)
    {:ok, Enum.map(villagers, &Villager.to_api_map/1)}
  end

  @impl true
  def list_items(category) do
    items = Repo.all(from i in Item, where: i.subcategory == ^category, order_by: i.name)
    {:ok, Enum.map(items, &Item.to_api_map/1)}
  end
end

defmodule CreatureCrossing.NookipediaTest do
  use ExUnit.Case, async: true

  alias CreatureCrossing.Nookipedia

  describe "list_bugs/0" do
    test "returns {:ok, list} with expected critter fields" do
      assert {:ok, bugs} = Nookipedia.list_bugs()
      assert length(bugs) > 0

      bug = hd(bugs)
      assert is_binary(bug["name"])
      assert is_binary(bug["image_url"])
      assert is_integer(bug["number"])
      assert is_binary(bug["location"])
      assert is_binary(bug["rarity"])
      assert is_integer(bug["sell_nook"])
      assert is_map(bug["north"])
      assert is_map(bug["south"])
    end

    test "critters have hemisphere availability data" do
      {:ok, [bug | _]} = Nookipedia.list_bugs()

      north = bug["north"]
      assert is_list(north["availability_array"])
      assert is_list(north["months_array"])
      assert is_map(north["times_by_month"])
    end
  end

  describe "list_fish/0" do
    test "returns {:ok, list} of fish" do
      assert {:ok, fish} = Nookipedia.list_fish()
      assert length(fish) > 0
      assert is_binary(hd(fish)["name"])
    end
  end

  describe "list_sea_creatures/0" do
    test "returns {:ok, list} of sea creatures" do
      assert {:ok, creatures} = Nookipedia.list_sea_creatures()
      assert length(creatures) > 0
      assert is_binary(hd(creatures)["name"])
    end
  end

  describe "list_villagers/0" do
    test "returns {:ok, list} with expected villager fields" do
      assert {:ok, villagers} = Nookipedia.list_villagers()
      assert length(villagers) > 0

      villager = hd(villagers)
      assert is_binary(villager["name"])
      assert is_binary(villager["image_url"])
      assert is_binary(villager["species"])
      assert is_binary(villager["personality"])
      assert is_binary(villager["gender"])
      assert is_binary(villager["birthday_month"])
      assert is_binary(villager["birthday_day"])
      assert is_binary(villager["sign"])
      assert is_binary(villager["hobby"])
      assert is_list(villager["fav_colors"])
      assert is_list(villager["fav_styles"])
    end

    test "returns enough villagers for Guess Who" do
      {:ok, villagers} = Nookipedia.list_villagers()
      assert length(villagers) >= 24
    end
  end

  describe "list_items/1" do
    test "returns items for each valid category" do
      for category <- ~w(furniture clothing art fossils) do
        assert {:ok, items} = Nookipedia.list_items(category)
        assert length(items) > 0

        item = hd(items)
        assert is_binary(item["name"])
        assert is_binary(item["image_url"])
      end
    end
  end
end

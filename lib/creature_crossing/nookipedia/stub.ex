defmodule CreatureCrossing.Nookipedia.Stub do
  @moduledoc """
  Stubbed Nookipedia API client with realistic data matching the real API
  response structure. Used in dev (until API key arrives) and test.
  """
  @behaviour CreatureCrossing.Nookipedia

  @impl true
  def list_bugs do
    {:ok, [
      critter("Common butterfly", 1, "Flying", "Common", 160, %{
        months: "Sep – Jun", time: "4 AM – 7 PM",
        months_array: [1,2,3,4,5,6,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,9,10,11,12], "4 AM – 7 PM")
      }, %{
        months: "Mar – Dec", time: "4 AM – 7 PM",
        months_array: [3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([3,4,5,6,7,8,9,10,11,12], "4 AM – 7 PM")
      }),
      critter("Monarch butterfly", 2, "Flying", "Common", 140, %{
        months: "Sep – Nov", time: "4 AM – 5 PM",
        months_array: [9,10,11],
        times: monthly_times([9,10,11], "4 AM – 5 PM")
      }, %{
        months: "Mar – May", time: "4 AM – 5 PM",
        months_array: [3,4,5],
        times: monthly_times([3,4,5], "4 AM – 5 PM")
      }),
      critter("Honeybee", 3, "Flying", "Common", 200, %{
        months: "Mar – Jul", time: "8 AM – 5 PM",
        months_array: [3,4,5,6,7],
        times: monthly_times([3,4,5,6,7], "8 AM – 5 PM")
      }, %{
        months: "Sep – Jan", time: "8 AM – 5 PM",
        months_array: [9,10,11,12,1],
        times: monthly_times([9,10,11,12,1], "8 AM – 5 PM")
      }),
      critter("Tarantula", 4, "On ground", "Rare", 8000, %{
        months: "Nov – Apr", time: "7 PM – 4 AM",
        months_array: [1,2,3,4,11,12],
        times: monthly_times([1,2,3,4,11,12], "7 PM – 4 AM")
      }, %{
        months: "May – Oct", time: "7 PM – 4 AM",
        months_array: [5,6,7,8,9,10],
        times: monthly_times([5,6,7,8,9,10], "7 PM – 4 AM")
      }),
      critter("Emperor butterfly", 5, "Flying", "Uncommon", 4000, %{
        months: "Jun – Sep", time: "5 PM – 8 AM",
        months_array: [6,7,8,9],
        times: monthly_times([6,7,8,9], "5 PM – 8 AM")
      }, %{
        months: "Dec – Mar", time: "5 PM – 8 AM",
        months_array: [12,1,2,3],
        times: monthly_times([12,1,2,3], "5 PM – 8 AM")
      }),
      critter("Scorpion", 6, "On ground", "Rare", 8000, %{
        months: "May – Oct", time: "7 PM – 4 AM",
        months_array: [5,6,7,8,9,10],
        times: monthly_times([5,6,7,8,9,10], "7 PM – 4 AM")
      }, %{
        months: "Nov – Apr", time: "7 PM – 4 AM",
        months_array: [11,12,1,2,3,4],
        times: monthly_times([11,12,1,2,3,4], "7 PM – 4 AM")
      }),
      critter("Atlas moth", 7, "On trees", "Uncommon", 3000, %{
        months: "Apr – Sep", time: "7 PM – 4 AM",
        months_array: [4,5,6,7,8,9],
        times: monthly_times([4,5,6,7,8,9], "7 PM – 4 AM")
      }, %{
        months: "Oct – Mar", time: "7 PM – 4 AM",
        months_array: [10,11,12,1,2,3],
        times: monthly_times([10,11,12,1,2,3], "7 PM – 4 AM")
      })
    ]}
  end

  @impl true
  def list_fish do
    {:ok, [
      critter("Sea bass", 1, "Sea", "Very Common", 400, %{
        months: "All year", time: "All day",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "All day")
      }, %{
        months: "All year", time: "All day",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "All day")
      }),
      critter("Pale chub", 2, "River", "Common", 200, %{
        months: "All year", time: "9 AM – 4 PM",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "9 AM – 4 PM")
      }, %{
        months: "All year", time: "9 AM – 4 PM",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "9 AM – 4 PM")
      }),
      critter("Coelacanth", 3, "Sea (Rain)", "Ultra-rare", 15000, %{
        months: "All year", time: "All day",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "All day")
      }, %{
        months: "All year", time: "All day",
        months_array: [1,2,3,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,8,9,10,11,12], "All day")
      }),
      critter("Tuna", 4, "Pier", "Rare", 7000, %{
        months: "Nov – Apr", time: "All day",
        months_array: [1,2,3,4,11,12],
        times: monthly_times([1,2,3,4,11,12], "All day")
      }, %{
        months: "May – Oct", time: "All day",
        months_array: [5,6,7,8,9,10],
        times: monthly_times([5,6,7,8,9,10], "All day")
      }),
      critter("Oarfish", 5, "Sea", "Rare", 9000, %{
        months: "Dec – May", time: "All day",
        months_array: [1,2,3,4,5,12],
        times: monthly_times([1,2,3,4,5,12], "All day")
      }, %{
        months: "Jun – Nov", time: "All day",
        months_array: [6,7,8,9,10,11],
        times: monthly_times([6,7,8,9,10,11], "All day")
      }),
      critter("Golden trout", 6, "River (Clifftop)", "Rare", 15000, %{
        months: "Mar – May; Sep – Nov", time: "4 PM – 9 AM",
        months_array: [3,4,5,9,10,11],
        times: monthly_times([3,4,5,9,10,11], "4 PM – 9 AM")
      }, %{
        months: "Sep – Nov; Mar – May", time: "4 PM – 9 AM",
        months_array: [3,4,5,9,10,11],
        times: monthly_times([3,4,5,9,10,11], "4 PM – 9 AM")
      })
    ]}
  end

  @impl true
  def list_sea_creatures do
    {:ok, [
      critter("Seaweed", 1, "Sea (Diving)", "Common", 600, %{
        months: "Oct – Jul", time: "All day",
        months_array: [1,2,3,4,5,6,7,10,11,12],
        times: monthly_times([1,2,3,4,5,6,7,10,11,12], "All day")
      }, %{
        months: "Apr – Jan", time: "All day",
        months_array: [1,4,5,6,7,8,9,10,11,12],
        times: monthly_times([1,4,5,6,7,8,9,10,11,12], "All day")
      }),
      critter("Sea cucumber", 2, "Sea (Diving)", "Common", 500, %{
        months: "Nov – Apr", time: "All day",
        months_array: [1,2,3,4,11,12],
        times: monthly_times([1,2,3,4,11,12], "All day")
      }, %{
        months: "May – Oct", time: "All day",
        months_array: [5,6,7,8,9,10],
        times: monthly_times([5,6,7,8,9,10], "All day")
      }),
      critter("Sea pig", 3, "Sea (Diving)", "Uncommon", 10000, %{
        months: "Nov – Feb", time: "4 PM – 9 AM",
        months_array: [1,2,11,12],
        times: monthly_times([1,2,11,12], "4 PM – 9 AM")
      }, %{
        months: "May – Aug", time: "4 PM – 9 AM",
        months_array: [5,6,7,8],
        times: monthly_times([5,6,7,8], "4 PM – 9 AM")
      }),
      critter("Vampire squid", 4, "Sea (Diving)", "Rare", 10000, %{
        months: "May – Aug", time: "4 PM – 9 AM",
        months_array: [5,6,7,8],
        times: monthly_times([5,6,7,8], "4 PM – 9 AM")
      }, %{
        months: "Nov – Feb", time: "4 PM – 9 AM",
        months_array: [1,2,11,12],
        times: monthly_times([1,2,11,12], "4 PM – 9 AM")
      }),
      critter("Moon jellyfish", 5, "Sea (Diving)", "Common", 600, %{
        months: "Jul – Sep", time: "All day",
        months_array: [7,8,9],
        times: monthly_times([7,8,9], "All day")
      }, %{
        months: "Jan – Mar", time: "All day",
        months_array: [1,2,3],
        times: monthly_times([1,2,3], "All day")
      })
    ]}
  end

  @impl true
  def list_villagers do
    {:ok, [
      villager("Raymond", "Cat", "Smug", "Male", "October", "1", "Libra", "Nature", ["Gray", "Green"], ["Cool", "Gorgeous"]),
      villager("Marshal", "Squirrel", "Smug", "Male", "September", "29", "Libra", "Music", ["Beige", "Green"], ["Cute", "Elegant"]),
      villager("Ankha", "Cat", "Snooty", "Female", "September", "22", "Virgo", "Nature", ["Yellow", "Orange"], ["Gorgeous", "Elegant"]),
      villager("Judy", "Cub", "Snooty", "Female", "March", "10", "Pisces", "Nature", ["Pink", "Blue"], ["Cute", "Gorgeous"]),
      villager("Bob", "Cat", "Lazy", "Male", "January", "1", "Capricorn", "Play", ["Orange", "Purple"], ["Simple", "Cool"]),
      villager("Marina", "Octopus", "Normal", "Female", "June", "26", "Cancer", "Play", ["Pink", "Red"], ["Cute", "Simple"]),
      villager("Zucker", "Octopus", "Lazy", "Male", "March", "8", "Pisces", "Play", ["Red", "Orange"], ["Simple", "Active"]),
      villager("Dom", "Sheep", "Jock", "Male", "March", "18", "Pisces", "Play", ["Red", "Colorful"], ["Active", "Simple"]),
      villager("Sherb", "Goat", "Lazy", "Male", "January", "18", "Capricorn", "Nature", ["Blue", "Aqua"], ["Simple", "Cute"]),
      villager("Diana", "Deer", "Snooty", "Female", "January", "4", "Capricorn", "Education", ["White", "Pink"], ["Gorgeous", "Elegant"]),
      villager("Fauna", "Deer", "Normal", "Female", "March", "26", "Aries", "Nature", ["Green", "Beige"], ["Simple", "Cute"]),
      villager("Maple", "Cub", "Normal", "Female", "June", "15", "Gemini", "Nature", ["Beige", "Brown"], ["Cute", "Simple"]),
      villager("Stitches", "Cub", "Lazy", "Male", "February", "10", "Aquarius", "Play", ["Colorful", "Orange"], ["Cute", "Active"]),
      villager("Molly", "Duck", "Normal", "Female", "March", "7", "Pisces", "Nature", ["Orange", "Brown"], ["Simple", "Cute"]),
      villager("Lucky", "Dog", "Lazy", "Male", "November", "4", "Scorpio", "Play", ["Yellow", "Orange"], ["Simple", "Cool"]),
      villager("Audie", "Wolf", "Peppy", "Female", "August", "31", "Virgo", "Fitness", ["Yellow", "Orange"], ["Active", "Cool"]),
      villager("Whitney", "Wolf", "Snooty", "Female", "September", "17", "Virgo", "Fashion", ["White", "Blue"], ["Gorgeous", "Elegant"]),
      villager("Coco", "Rabbit", "Normal", "Female", "March", "1", "Pisces", "Education", ["Brown", "Beige"], ["Simple", "Gorgeous"]),
      villager("Roald", "Penguin", "Jock", "Male", "January", "5", "Capricorn", "Fitness", ["Blue", "White"], ["Active", "Cool"]),
      villager("Beau", "Deer", "Lazy", "Male", "April", "5", "Aries", "Nature", ["Green", "Brown"], ["Simple", "Cute"]),
      villager("Merengue", "Rhino", "Normal", "Female", "March", "19", "Pisces", "Nature", ["White", "Pink"], ["Cute", "Simple"]),
      villager("Ketchup", "Duck", "Peppy", "Female", "July", "27", "Leo", "Play", ["Red", "Yellow"], ["Cute", "Active"]),
      villager("Cherry", "Dog", "Sisterly", "Female", "May", "11", "Taurus", "Music", ["Red", "Black"], ["Cool", "Active"]),
      villager("Apollo", "Eagle", "Cranky", "Male", "July", "4", "Cancer", "Music", ["Black", "Blue"], ["Cool", "Gorgeous"]),
      villager("Tia", "Elephant", "Normal", "Female", "November", "18", "Scorpio", "Nature", ["Blue", "Aqua"], ["Cute", "Elegant"]),
      villager("Pietro", "Sheep", "Smug", "Male", "April", "19", "Aries", "Education", ["Colorful", "Red"], ["Gorgeous", "Cute"]),
      villager("Punchy", "Cat", "Lazy", "Male", "April", "11", "Aries", "Play", ["Red", "Black"], ["Simple", "Cool"]),
      villager("Lolly", "Cat", "Normal", "Female", "March", "27", "Aries", "Education", ["Gray", "Yellow"], ["Simple", "Cute"]),
      villager("Cephalobot", "Octopus", "Cranky", "Male", "April", "20", "Taurus", "Education", ["Blue", "Black"], ["Cool", "Gorgeous"]),
      villager("Sasha", "Rabbit", "Lazy", "Male", "May", "19", "Taurus", "Music", ["Blue", "White"], ["Simple", "Cute"]),
      villager("Shino", "Deer", "Peppy", "Female", "October", "9", "Libra", "Fashion", ["Red", "Black"], ["Gorgeous", "Cool"])
    ]}
  end

  @impl true
  def list_items("furniture") do
    {:ok, [
      %{"name" => "Ironwood Dresser", "image_url" => "https://dodo.ac/np/images/thumb/1/17/Ironwood_Dresser.png/128px-Ironwood_Dresser.png"},
      %{"name" => "Log Bench", "image_url" => "https://dodo.ac/np/images/thumb/a/a6/Log_Bench.png/128px-Log_Bench.png"},
      %{"name" => "Shell Table", "image_url" => "https://dodo.ac/np/images/thumb/4/4d/Shell_Table.png/128px-Shell_Table.png"},
      %{"name" => "Wooden Bookshelf", "image_url" => "https://dodo.ac/np/images/thumb/2/2a/Wooden_Bookshelf.png/128px-Wooden_Bookshelf.png"},
      %{"name" => "Rattan Armchair", "image_url" => "https://dodo.ac/np/images/thumb/e/e4/Rattan_Armchair.png/128px-Rattan_Armchair.png"}
    ]}
  end

  def list_items("clothing") do
    {:ok, [
      %{"name" => "Aloha Shirt", "image_url" => "https://dodo.ac/np/images/thumb/a/a5/Aloha_Shirt.png/128px-Aloha_Shirt.png"},
      %{"name" => "Tuxedo", "image_url" => "https://dodo.ac/np/images/thumb/c/c5/Tuxedo.png/128px-Tuxedo.png"},
      %{"name" => "Royal Crown", "image_url" => "https://dodo.ac/np/images/thumb/c/c2/Royal_Crown.png/128px-Royal_Crown.png"}
    ]}
  end

  def list_items("art") do
    {:ok, [
      %{"name" => "Famous Painting", "image_url" => "https://dodo.ac/np/images/thumb/0/0e/Famous_Painting.png/128px-Famous_Painting.png"},
      %{"name" => "Scenic Painting", "image_url" => "https://dodo.ac/np/images/thumb/4/47/Scenic_Painting.png/128px-Scenic_Painting.png"},
      %{"name" => "Beautiful Statue", "image_url" => "https://dodo.ac/np/images/thumb/5/5c/Beautiful_Statue.png/128px-Beautiful_Statue.png"}
    ]}
  end

  def list_items("fossils") do
    {:ok, [
      %{"name" => "T. Rex Skull", "image_url" => "https://dodo.ac/np/images/thumb/f/fc/T._Rex_Skull.png/128px-T._Rex_Skull.png"},
      %{"name" => "Amber", "image_url" => "https://dodo.ac/np/images/thumb/b/b3/Amber.png/128px-Amber.png"},
      %{"name" => "Trilobite", "image_url" => "https://dodo.ac/np/images/thumb/d/d4/Trilobite.png/128px-Trilobite.png"}
    ]}
  end

  def list_items(_category), do: {:ok, []}

  # -- Helpers for building stub data --

  defp critter(name, number, location, rarity, sell_nook, north_data, south_data) do
    %{
      "name" => name,
      "image_url" => "https://dodo.ac/np/images/thumb/#{String.replace(name, " ", "_")}.png/128px-#{String.replace(name, " ", "_")}.png",
      "number" => number,
      "location" => location,
      "rarity" => rarity,
      "sell_nook" => sell_nook,
      "north" => %{
        "availability_array" => [%{"months" => north_data.months, "time" => north_data.time}],
        "months_array" => north_data.months_array,
        "times_by_month" => north_data.times
      },
      "south" => %{
        "availability_array" => [%{"months" => south_data.months, "time" => south_data.time}],
        "months_array" => south_data.months_array,
        "times_by_month" => south_data.times
      }
    }
  end

  defp villager(name, species, personality, gender, bday_month, bday_day, sign, hobby, fav_colors, fav_styles) do
    %{
      "name" => name,
      "image_url" => "/images/critter_placeholder.svg",
      "species" => species,
      "personality" => personality,
      "gender" => gender,
      "birthday_month" => bday_month,
      "birthday_day" => bday_day,
      "sign" => sign,
      "hobby" => hobby,
      "fav_colors" => fav_colors,
      "fav_styles" => fav_styles
    }
  end

  defp monthly_times(months, time) do
    Map.new(months, fn m -> {to_string(m), time} end)
  end
end

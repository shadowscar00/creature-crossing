defmodule CreatureCrossing.RansomNotes.WordPool do
  @moduledoc """
  Word pool and prompt data for the Ransom Notes game.
  All words are single tokens — no compound phrases.
  """

  @prompts [
    "Write a letter convincing Tom Nook to forgive your home loan",
    "Compose a love letter to your favorite villager",
    "Write a complaint to Isabelle about your neighbor",
    "Pitch a new island getaway package to Dodo Airlines",
    "Write a review of The Roost coffee shop",
    "Describe your dream island to a potential visitor",
    "Write a ransom note demanding 99,000 bells",
    "Compose a resignation letter to Nook Inc",
    "Write an apology to Blathers for donating so many bugs",
    "Convince K.K. Slider to play at your birthday party",
    "Write a strongly worded letter to Redd about his fake art",
    "Draft a petition to make your villager the island representative",
    "Write a letter begging Daisy Mae for a turnip discount",
    "Compose a thank you note to Sable for teaching you to sew",
    "Write a complaint to the Happy Home Academy about your rating",
    "Convince Celeste to give you her best star fragment recipe",
    "Write a tourism brochure for your island",
    "Draft a warning letter about the tarantula infestation",
    "Write a breakup letter to a villager who wants to move away",
    "Compose a formal request to Tortimer for island access",
    "Write a letter to your mom explaining why you moved to an island",
    "Pitch a new shop idea to the Nooklings",
    "Write a missing poster for your favorite gyroid",
    "Compose a campaign speech for island representative election",
    "Write a Yelp review of Able Sisters"
  ]

  # Characters and proper nouns (all single words)
  @character_words ~w(
    tom nook isabelle blathers celeste flick
    cj daisy mae redd kicks sahara
    brewster sable mabel label timmy tommy
    tortimer kapp wisp gulliver gullivarrr
    pascal leif rover harriet katrina jack
    zipper joan lottie digby resetti
    villager resident player islander neighbor
  )

  # Personalities, hobbies, and styles
  @personality_words ~w(
    lazy smug peppy cranky snooty jock
    uchi normal sisterly grumpy cheerful
    cool elegant gorgeous cute simple active
    education fitness fashion nature music play
  )

  # Island life and activities
  @island_words ~w(
    island paradise beach ocean river lake
    pond waterfall cliff bridge incline
    plaza museum shop cafe airport dock
    tent house mansion basement attic
    garden orchard campsite lighthouse
    fishing catching digging planting watering
    shaking crafting decorating terraforming
    swimming diving snorkeling stargazing
    fossil bug fish sea creature artwork
    flower tree fruit weed shell sand
    apples oranges peaches pears cherries coconuts
    roses tulips lilies hyacinths cosmos
    mums pansies windflowers
  )

  # Items, currency, and game mechanics
  @item_words ~w(
    bells nook miles tickets turnips
    mortgage loan debt interest payment
    shovel axe net rod slingshot
    wand ladder vaulting pole wetsuit
    recipe diy workbench tools material
    wood stone iron clay gold nugget
    star fragment pearl bamboo mushroom
    balloon present bottle message fossil
    gyroid song vinyl record player
    stalk market stonks profit loss
    tarantula scorpion butterfly beetle
    shark tuna bass coelacanth oarfish
    nookphone critterpedia catalog upgrade
  )

  # Emotions and descriptors
  @emotion_words ~w(
    happy sad angry excited nervous calm
    beautiful ugly amazing terrible wonderful
    awful lovely adorable hideous stunning
    cozy peaceful chaotic cursed blessed
    suspicious shady sketchy legitimate rare
    legendary mythical ordinary boring magnificent
    tiny huge enormous precious worthless
    haunted spooky festive magical sparkly
  )

  # Actions and verbs
  @action_words ~w(
    give take sell buy trade donate display
    collect catch dig plant water shake craft
    build destroy move demolish upgrade
    visit invite welcome kick evict
    sing dance play run walk fly swim
    hide seek steal borrow return
    love hate want need demand beg
    please thank sorry help celebrate
    complain scream whisper gossip confess
    bury discover hoard smuggle escape
    time travel reset regret
  )

  # Connectors and common English (needed to form sentences)
  @connector_words ~w(
    the a an and but or so if when because
    is are was were will would can could should
    my your our their this that every some
    many few all no not never always
    very really quite extremely absolutely
    with from about into over under between
    here there now then today tomorrow
    one two three four five hundred thousand
    million just only still even also again
    yes no maybe perhaps definitely
    well good bad best worst most least
    big small great little old new first last
    more less too much very
    for at on in of to up by
  )

  # Seasonal and event words
  @event_words ~w(
    spring summer autumn winter
    rain snow sun cloud wind thunder
    morning evening night weekend
    party festival concert picnic ceremony
    birthday wedding holiday halloween
    harvest bunny fishing tourney
    fireworks meteor shower aurora
    new year valentine easter
  )

  # Community culture and meta references
  @culture_words ~w(
    dreamie villager hunting mystery
    nook inc corporate grind hustle
    catalog everything completionist
    hybrid breeding golden watering
    money rock tree bell voucher
    deserted getaway package
    southern northern hemisphere
    pocket camp horizons leaf
    wild world city folk
    amiibo card invite move
    plot empty void full
    entrance path custom design
    pattern creator pro
  )

  @all_words @character_words ++
             @personality_words ++
             @island_words ++
             @item_words ++
             @emotion_words ++
             @action_words ++
             @connector_words ++
             @event_words ++
             @culture_words

  @doc "Returns a random prompt string."
  def random_prompt do
    Enum.random(@prompts)
  end

  @doc "Returns a list of all available prompts."
  def all_prompts, do: @prompts

  @doc "Returns `count` random word tiles, each with a unique id."
  def random_tiles(count) do
    @all_words
    |> Enum.shuffle()
    |> Enum.take(count)
    |> Enum.map(fn word ->
      %{id: System.unique_integer([:positive, :monotonic]), word: word}
    end)
  end

  @doc "Returns the total number of unique words in the pool."
  def pool_size, do: length(@all_words)
end

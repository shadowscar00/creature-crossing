defmodule CreatureCrossing.RansomNotes.WordPool do
  @moduledoc """
  Word pool and prompt data for the Ransom Notes game.
  All words are single tokens — no compound phrases.
  Words use root forms only (no -ing, -s, -ed suffixes).
  Suffix tiles (ing, s, d, ed, er, ly) are provided for players to append.
  """

  @prompts [
    # Positive / heartfelt
    "Write a letter convincing Tom Nook to forgive your home loan",
    "Compose a love letter to your favorite villager",
    "Write a review of The Roost coffee shop",
    "Describe your dream island to a potential visitor",
    "Compose a thank you note to Sable for teaching you to sew",
    "Convince Celeste to give you her best star fragment recipe",
    "Write a tourism brochure for your island",
    "Write a letter to your mom explaining why you moved to an island",
    "Pitch a new shop idea to the Nooklings",
    "Write a missing poster for your favorite gyroid",
    "Convince K.K. Slider to play at your birthday party",
    "Pitch a new island getaway package to Dodo Airlines",
    "Write a letter begging Daisy Mae for a turnip discount",
    "Compose a formal request to Tortimer for island access",
    "Write a Yelp review of Able Sisters",
    # Negative / confrontational
    "Write a complaint to Isabelle about your neighbor",
    "Write a ransom note demanding 99,000 bells",
    "Compose a resignation letter to Nook Inc",
    "Write a strongly worded letter to Redd about his fake art",
    "Draft a warning letter about the tarantula infestation",
    "Write a breakup letter to a villager who wants to move away",
    "Write a complaint to the Happy Home Academy about your rating",
    "Write an anonymous bulletin to complain about cockroaches",
    "Tell Blathers to get over his fear of bugs",
    "Announce to your island that you have uncovered Zipper's real identity",
    "Write a threat to whoever keeps running through your flower garden",
    "Write an apology to an imperfect snowperson",
    "Draft a petition to make a villager the new island representative",
    # Meta / meme
    "Explain to another player why they do not deserve to have Marshal on their island",
    "Write a message to Nintendo telling them to bring back star trees",
    "Write a message to Nintendo demanding the return of mean villagers",
    "Explain why Amiibo Festival was actually the best Animal Crossing game",
    "Compose a campaign speech for island representative election",
    "Write an apology to Blathers for donating so many bugs"
  ]

  # All special characters from every AC game (single words only)
  @character_words ~w(
    Tom Nook Isabelle Blathers Celeste Flick
    CJ Daisy Mae Redd Kicks Saharah
    Brewster Sable Mabel Label Timmy Tommy
    Tortimer Wisp Gulliver Gullivarrr
    Pascal Leif Rover Harriet Katrina Jack
    Zipper Joan Lottie Digby Resetti
    Cyrus Reese Harvey Luna Lyle
    Pelly Pete Phyllis Porter
    Copper Booker Gracie Wendell
    Phineas Serena Shrunk Nat Pave
    Chip Kaitlin Katie Franklin Jingle
    Cornimer Farley Lloid Blanca
    Orville Wilbur Niko Wardell
    Don Epona Ganon Link Medli
    Felyne Inkwell Cece Viche
    Beppe Carlo Giovanni
    Ai Yu Champ Frillard
    Mineru Tulin Leilani Leila Gram
    Snowboy Snowmam Snowman Snowtyke
    villager resident islander neighbor
  )

  # Villager species
  @species_words ~w(
    alligator anteater bear bird bull cat
    chicken cow cub deer dog duck eagle
    elephant frog goat gorilla hamster hippo
    horse kangaroo koala lion monkey mouse
    octopus ostrich penguin pig rabbit rhino
    sheep squirrel tiger wolf
  )

  # Personalities, hobbies, and styles
  @personality_words ~w(
    lazy smug peppy cranky snooty jock
    uchi normal sisterly grumpy cheerful
    cool elegant gorgeous cute simple active
    education fitness fashion nature music
  )

  # Island life and activities (root forms only)
  @island_words ~w(
    island paradise beach ocean river lake
    pond waterfall cliff bridge incline
    plaza museum shop cafe airport dock
    tent house mansion basement attic
    garden orchard campsite lighthouse
    fossil bug fish sea creature artwork
    flower tree fruit weed shell sand
    leaf ground dirt rock mud path
    hill slope mountain peak valley
    apple orange peach pear cherry coconut
    rose tulip lily hyacinth cosmo
    mum pansy windflower
    bush hedge fence gate sign
    reef tide shore coast bay
  )

  # Items, currency, and game mechanics
  @item_words ~w(
    bell mile ticket turnip
    mortgage loan debt interest payment
    shovel axe net rod slingshot
    wand ladder pole wetsuit
    recipe diy workbench tool material
    wood stone iron clay gold nugget
    star fragment pearl bamboo mushroom
    balloon present bottle message
    gyroid song vinyl record
    stalk market stonk profit loss
    tarantula scorpion butterfly beetle
    wasp bee hive flea cockroach
    shark tuna bass coelacanth oarfish
    nookphone critterpedia catalog
  )

  # Emotions and descriptors (root forms, no -ed suffixes)
  @emotion_words ~w(
    happy sad angry excite nervous calm
    beautiful ugly amaze terrible wonderful
    awful lovely adorable hideous stun
    cozy peaceful chaotic curse bless
    suspicious shady sketchy legitimate rare
    legendary mythical ordinary bore magnificent
    tiny huge enormous precious worthless
    haunt spooky festive magical sparkle
    small medium large
  )

  # Actions and verbs (root forms only)
  @action_words ~w(
    give take sell buy trade donate display
    collect catch dig plant water shake craft
    build destroy move demolish upgrade
    visit invite welcome evict
    sing dance play run walk fly swim
    hide seek steal borrow return
    love hate want need demand beg
    please thank sorry help celebrate
    complain scream whisper gossip confess
    bury discover hoard smuggle escape
    time travel reset regret
    farm cook eat sleep wake
  )

  # Pronouns and question words
  @pronoun_words ~w(
    I me my mine myself
    you your yours yourself
    he him his she her hers
    it we us our ours
    they them their theirs
    who what where why how
    which whose whom
    someone something anyone anything
    everyone everything nobody nothing
  )

  # Common verbs (root forms, not covered by action_words)
  @common_verbs ~w(
    be have do make go come see
    look find know think feel say
    tell ask try use put keep let
    start show turn call hold
    stand sit open close read write
    speak talk hear listen learn teach
    bring send leave meet wait watch
    seem become grow change follow lead
    lose win break cut hit pull push
    pick carry throw touch reach set
    lay rise wear choose spend happen
    remember forget believe hope wish
    mean belong stay pass join share
    add fill miss wonder suppose
  )

  # Connectors, prepositions, and common English
  @connector_words ~w(
    the a an and but or so if when because
    is are was were will would can could should
    shall may might must
    this that these those every some
    many few all no not never always
    very really quite extreme absolute
    with from about into over under between
    behind beside near through during
    before after above below around
    against along across toward upon
    among until onto without within
    here there now then today tomorrow
    one two three four five six seven eight nine ten
    hundred thousand million
    just only still even also again
    yes maybe perhaps definite
    well good bad best worst most least
    big great little old first last
    more less too much
    for at on in of to up by
    away back down off out
    than as like such
    own other another each both either neither
    same different next
    enough almost already yet
  )

  # Seasonal and event words
  @event_words ~w(
    spring summer autumn winter
    rain snow sun cloud wind thunder
    morning evening night weekend
    party festival concert picnic ceremony
    birthday wedding holiday halloween
    harvest bunny tourney
    firework meteor shower aurora
    new year valentine easter
  )

  # Community culture and meta references
  @culture_words ~w(
    dreamie hunt mystery
    inc corporate grind hustle
    complete hybrid breed golden
    money voucher
    desert getaway package
    southern northern hemisphere
    pocket camp horizon
    wild world city folk
    amiibo card plot
    empty void full
    entrance custom design
    pattern creator pro
    Marshal Raymond Ankha
    Nintendo update patch
    stop terminal
  )

  # Expressive words and onomatopoeia
  @expressive_words ~w(
    yay ugh boo bang crash boom yikes
    whoa ooh ahh eek oof hmm shh
    wow haha oops gulp mwah poof splat
    honk ribbit screech sigh gasp growl
    meow woof quack cluck moo baa neigh
    squeak chirp hiss roar buzz croak
  )

  # Punctuation marks (single characters, except ellipsis)
  @punctuation ~w(! ? . , : ; - ... ~)

  # Suffix tiles for players to append to root words
  @suffix_words ~w(
    s d ed ing er ly
  )

  @all_words @character_words ++
             @species_words ++
             @personality_words ++
             @island_words ++
             @item_words ++
             @emotion_words ++
             @action_words ++
             @pronoun_words ++
             @common_verbs ++
             @connector_words ++
             @event_words ++
             @culture_words ++
             @expressive_words ++
             @punctuation ++
             @suffix_words

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

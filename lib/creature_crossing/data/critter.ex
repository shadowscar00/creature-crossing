defmodule CreatureCrossing.Data.Critter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "critters" do
    field :type, :string
    field :name, :string
    field :location, :string
    field :weather, :string
    field :rarity, :string
    field :sell_nook, :string
    field :sell_special, :string
    field :time, :string
    field :months_north, :string
    field :months_south, :string
    field :north_data, :string
    field :south_data, :string
    field :shadow_size, :string
    field :speed, :string
    field :catchphrase, :string
    field :icon_url, :string

    timestamps()
  end

  def changeset(critter, attrs) do
    critter
    |> cast(attrs, [
      :type, :name, :location, :weather, :rarity, :sell_nook, :sell_special,
      :time, :months_north, :months_south, :north_data, :south_data,
      :shadow_size, :speed, :catchphrase, :icon_url
    ])
    |> validate_required([:type, :name])
    |> unique_constraint([:type, :name])
  end

  @doc """
  Converts a Critter struct to the string-keyed map format the Stub uses,
  including parsed hemisphere data blobs for the overlap calculator.
  """
  def to_api_map(%__MODULE__{} = c) do
    north = decode_json(c.north_data, %{})
    south = decode_json(c.south_data, %{})

    %{
      "name" => c.name,
      "image_url" => c.icon_url || "/images/critter_placeholder.svg",
      "number" => c.id,
      "critter_type" => c.type,
      "location" => c.location,
      "weather" => c.weather,
      "rarity" => c.rarity,
      "sell_nook" => parse_int_or_string(c.sell_nook),
      "shadow_size" => c.shadow_size,
      "speed" => c.speed,
      "north" => north,
      "south" => south
    }
  end

  defp decode_json(nil, default), do: default
  defp decode_json("", default), do: default

  defp decode_json(json, default) do
    case Jason.decode(json) do
      {:ok, data} -> data
      _ -> default
    end
  end

  defp parse_int_or_string(nil), do: 0

  defp parse_int_or_string(val) do
    case Integer.parse(val) do
      {n, ""} -> n
      _ -> val
    end
  end
end

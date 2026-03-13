defmodule CreatureCrossing.Data.Villager do
  use Ecto.Schema
  import Ecto.Changeset

  schema "villagers" do
    field :name, :string
    field :species, :string
    field :personality, :string
    field :gender, :string
    field :birthday, :string
    field :birthday_month, :string
    field :birthday_day, :string
    field :sign, :string
    field :catchphrase, :string
    field :hobby, :string
    field :fav_colors, :string
    field :fav_styles, :string
    field :icon_url, :string
    field :poster_url, :string
    field :amiibo_url, :string
    field :role, :string, default: "unclassified"

    timestamps()
  end

  def changeset(villager, attrs) do
    villager
    |> cast(attrs, [
      :name, :species, :personality, :gender, :birthday, :birthday_month,
      :birthday_day, :sign, :catchphrase, :hobby, :fav_colors, :fav_styles,
      :icon_url, :poster_url, :amiibo_url, :role
    ])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end

  def to_api_map(%__MODULE__{} = v) do
    %{
      "name" => v.name,
      "image_url" => v.icon_url || "/images/critter_placeholder.svg",
      "species" => v.species,
      "personality" => v.personality,
      "gender" => v.gender,
      "birthday_month" => v.birthday_month,
      "birthday_day" => v.birthday_day,
      "sign" => v.sign,
      "hobby" => v.hobby,
      "fav_colors" => decode_json(v.fav_colors, []),
      "fav_styles" => decode_json(v.fav_styles, []),
      "role" => v.role || "unclassified"
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
end

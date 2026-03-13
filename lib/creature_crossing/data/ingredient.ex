defmodule CreatureCrossing.Data.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingredients" do
    field :name, :string
    field :sell_price, :string
    field :stack, :string
    field :energy, :string
    field :icon_url, :string

    timestamps()
  end

  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:name, :sell_price, :stack, :energy, :icon_url])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end

  def to_api_map(%__MODULE__{} = i) do
    %{
      "name" => i.name,
      "image_url" => i.icon_url || "/images/critter_placeholder.svg"
    }
  end
end

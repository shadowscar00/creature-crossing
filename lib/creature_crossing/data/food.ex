defmodule CreatureCrossing.Data.Food do
  use Ecto.Schema
  import Ecto.Changeset

  schema "foods" do
    field :name, :string
    field :sell_price, :string
    field :energy, :string
    field :recipe, :string
    field :icon_url, :string

    timestamps()
  end

  def changeset(food, attrs) do
    food
    |> cast(attrs, [:name, :sell_price, :energy, :recipe, :icon_url])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end

  def to_api_map(%__MODULE__{} = f) do
    %{
      "name" => f.name,
      "image_url" => f.icon_url || "/images/critter_placeholder.svg"
    }
  end
end

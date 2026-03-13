defmodule CreatureCrossing.Data.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :subcategory, :string
    field :name, :string
    field :buy_price, :string
    field :sell_price, :string
    field :source, :string
    field :category, :string
    field :uses, :string
    field :variation, :string
    field :icon_url, :string

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :subcategory, :name, :buy_price, :sell_price, :source,
      :category, :uses, :variation, :icon_url
    ])
    |> validate_required([:subcategory, :name])
    |> unique_constraint([:subcategory, :name])
  end

  def to_api_map(%__MODULE__{} = i) do
    %{
      "name" => i.name,
      "image_url" => i.icon_url || "/images/critter_placeholder.svg"
    }
  end
end

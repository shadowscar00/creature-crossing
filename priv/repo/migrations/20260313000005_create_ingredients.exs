defmodule CreatureCrossing.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :name, :string, null: false
      add :sell_price, :string
      add :stack, :string
      add :energy, :string
      add :icon_url, :string

      timestamps()
    end

    create unique_index(:ingredients, [:name])
  end
end

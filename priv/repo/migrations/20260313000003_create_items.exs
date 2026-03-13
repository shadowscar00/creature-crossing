defmodule CreatureCrossing.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :subcategory, :string, null: false
      add :name, :string, null: false
      add :buy_price, :string
      add :sell_price, :string
      add :source, :string
      add :category, :string
      add :uses, :string
      add :variation, :string
      add :icon_url, :string

      timestamps()
    end

    create unique_index(:items, [:subcategory, :name])
  end
end

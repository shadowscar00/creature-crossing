defmodule CreatureCrossing.Repo.Migrations.CreateFoods do
  use Ecto.Migration

  def change do
    create table(:foods) do
      add :name, :string, null: false
      add :sell_price, :string
      add :energy, :string
      add :recipe, :text
      add :icon_url, :string

      timestamps()
    end

    create unique_index(:foods, [:name])
  end
end

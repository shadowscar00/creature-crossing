defmodule CreatureCrossing.Repo.Migrations.CreateCritters do
  use Ecto.Migration

  def change do
    create table(:critters) do
      add :type, :string, null: false
      add :name, :string, null: false
      add :location, :string
      add :weather, :string
      add :rarity, :string
      add :sell_nook, :string
      add :sell_special, :string
      add :time, :string
      add :months_north, :string
      add :months_south, :string
      add :north_data, :text
      add :south_data, :text
      add :shadow_size, :string
      add :speed, :string
      add :catchphrase, :string
      add :icon_url, :string

      timestamps()
    end

    create unique_index(:critters, [:type, :name])
  end
end

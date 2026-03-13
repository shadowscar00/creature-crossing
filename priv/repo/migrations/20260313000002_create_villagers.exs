defmodule CreatureCrossing.Repo.Migrations.CreateVillagers do
  use Ecto.Migration

  def change do
    create table(:villagers) do
      add :name, :string, null: false
      add :species, :string
      add :personality, :string
      add :gender, :string
      add :birthday, :string
      add :birthday_month, :string
      add :birthday_day, :string
      add :sign, :string
      add :catchphrase, :string
      add :hobby, :string
      add :fav_colors, :text
      add :fav_styles, :text
      add :icon_url, :string
      add :poster_url, :string
      add :amiibo_url, :string

      timestamps()
    end

    create unique_index(:villagers, [:name])
  end
end

defmodule CreatureCrossing.Repo.Migrations.AddRoleToVillagers do
  use Ecto.Migration

  def change do
    alter table(:villagers) do
      add :role, :string, default: "unclassified"
    end
  end
end

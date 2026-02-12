defmodule Fantasy.Repo.Migrations.AddDescriptionToTournaments do
  use Ecto.Migration

  def change do
    alter table("Tournament") do
      add :description, :string
    end
  end
end

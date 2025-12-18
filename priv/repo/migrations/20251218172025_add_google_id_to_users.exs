defmodule Fantasy.Repo.Migrations.AddGoogleIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:User) do
      add :google_id, :string
    end

    create unique_index(:User, [:google_id])
  end
end

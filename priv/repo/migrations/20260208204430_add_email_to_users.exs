defmodule Fantasy.Repo.Migrations.AddEmailToUsers do
  use Ecto.Migration

  def change do
    alter table(:User) do
      add :email, :string
    end

    create unique_index(:User, [:email])
  end
end

defmodule Fantasy.Repo.Migrations.CreateBaseTables do
  @moduledoc """
  Creates the base tables matching the existing Prisma schema.

  Table names use PascalCase and columns use camelCase to match Prisma conventions.
  Timestamps are stored as Unix milliseconds (integers).
  """
  use Ecto.Migration

  def change do
    # Create User table
    create_if_not_exists table(:User) do
      add :clerkId, :string
      add :name, :string, null: false
      add :isAdmin, :boolean, default: false
      add :createdAt, :bigint
      add :updatedAt, :bigint
    end

    create_if_not_exists unique_index(:User, [:clerkId])

    # Create Tournament table
    create_if_not_exists table(:Tournament) do
      add :deadline, :bigint, null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :maxTeams, :integer, default: 5
      add :maxPrice, :integer, default: 150
      add :spreadsheetUrl, :string
      add :teamColumnName, :string
      add :resultColumnName, :string
      add :createdAt, :bigint
      add :updatedAt, :bigint
    end

    create_if_not_exists unique_index(:Tournament, [:slug])

    # Create Team table
    create_if_not_exists table(:Team) do
      add :tournamentId, references(:Tournament, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :price, :integer, null: false
      add :points, :integer, default: 0
    end

    create_if_not_exists index(:Team, [:tournamentId])

    # Create Pick table
    create_if_not_exists table(:Pick) do
      add :userId, references(:User, on_delete: :delete_all), null: false
      add :tournamentId, references(:Tournament, on_delete: :delete_all), null: false
      add :teamIds, :string, null: false
      add :version, :integer, null: false
    end

    create_if_not_exists unique_index(:Pick, [:userId, :tournamentId])

    # Create IdealPick table
    create_if_not_exists table(:IdealPick) do
      add :tournamentId, references(:Tournament, on_delete: :delete_all), null: false
      add :teamIds, :string, null: false
      add :points, :integer, null: false
    end

    create_if_not_exists unique_index(:IdealPick, [:tournamentId])
  end
end

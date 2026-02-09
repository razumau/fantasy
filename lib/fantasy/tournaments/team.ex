defmodule Fantasy.Tournaments.Team do
  @moduledoc """
  Team schema mapping to the existing Prisma Team table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "Team" do
    field :name, :string
    field :price, :integer
    field :points, :integer, default: 0

    belongs_to :tournament, Fantasy.Tournaments.Tournament, foreign_key: :tournamentId
  end

  @doc """
  Changeset for creating a new team.
  """
  def create_changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :price, :points, :tournamentId])
    |> validate_required([:name, :price, :tournamentId])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:points, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:tournamentId)
  end

  @doc """
  Changeset for updating team details (name, price, points).
  """
  def update_changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :price, :points])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:points, greater_than_or_equal_to: 0)
  end
end

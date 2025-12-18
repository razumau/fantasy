defmodule Fantasy.Tournaments.IdealPick do
  @moduledoc """
  IdealPick schema mapping to the existing Prisma IdealPick table.

  Stores the optimal team selection for a tournament, calculated using
  a knapsack algorithm after the tournament closes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "IdealPick" do
    field :team_ids, :string, source: :teamIds
    field :points, :integer

    belongs_to :tournament, Fantasy.Tournaments.Tournament, foreign_key: :tournamentId
  end

  @doc """
  Changeset for creating or updating an ideal pick.
  """
  def changeset(ideal_pick, attrs) do
    ideal_pick
    |> cast(attrs, [:team_ids, :points, :tournamentId])
    |> validate_required([:team_ids, :points, :tournamentId])
    |> unique_constraint(:tournamentId,
      name: :IdealPick_tournamentId_key,
      message: "ideal pick already exists for this tournament"
    )
    |> foreign_key_constraint(:tournamentId)
  end

  @doc """
  Parses the team_ids JSON string and returns a list of integers.
  """
  def get_team_ids(%__MODULE__{team_ids: nil}), do: []
  def get_team_ids(%__MODULE__{team_ids: ""}), do: []
  def get_team_ids(%__MODULE__{team_ids: "[]"}), do: []

  def get_team_ids(%__MODULE__{team_ids: team_ids_json}) do
    case Jason.decode(team_ids_json) do
      {:ok, ids} when is_list(ids) -> ids
      _ -> []
    end
  end

  @doc """
  Converts a list of team IDs to a JSON string for storage.
  """
  def encode_team_ids(team_ids) when is_list(team_ids) do
    Jason.encode!(team_ids)
  end
end

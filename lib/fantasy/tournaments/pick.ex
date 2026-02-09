defmodule Fantasy.Tournaments.Pick do
  @moduledoc """
  Pick schema mapping to the existing Prisma Pick table.

  The teamIds field stores a JSON string of team IDs (e.g., "[1, 3, 5]").
  Use `get_team_ids/1` and `set_team_ids/2` to work with the parsed list.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "Pick" do
    field :team_ids, :string, source: :teamIds
    field :version, :integer

    belongs_to :user, Fantasy.Accounts.User, foreign_key: :userId
    belongs_to :tournament, Fantasy.Tournaments.Tournament, foreign_key: :tournamentId
  end

  @doc """
  Changeset for creating or updating a pick.
  """
  def changeset(pick, attrs) do
    pick
    |> cast(attrs, [:team_ids, :version, :userId, :tournamentId])
    |> validate_required([:team_ids, :version, :userId, :tournamentId])
    |> unique_constraint([:userId, :tournamentId],
      name: :Pick_userId_tournamentId_key,
      message: "user already has a pick for this tournament"
    )
    |> foreign_key_constraint(:userId)
    |> foreign_key_constraint(:tournamentId)
  end

  @doc """
  Parses the team_ids JSON string and returns a list of integers.
  Returns an empty list if the field is nil or empty.
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

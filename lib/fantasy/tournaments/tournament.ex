defmodule Fantasy.Tournaments.Tournament do
  @moduledoc """
  Tournament schema mapping to the existing Prisma Tournament table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "Tournament" do
    field :deadline, Fantasy.Ecto.UnixTimestamp
    field :title, :string
    field :slug, :string
    field :max_teams, :integer, default: 5, source: :maxTeams
    field :max_price, :integer, default: 150, source: :maxPrice
    field :spreadsheet_url, :string, source: :spreadsheetUrl
    field :team_column_name, :string, source: :teamColumnName
    field :result_column_name, :string, source: :resultColumnName
    field :created_at, Fantasy.Ecto.UnixTimestamp, source: :createdAt
    field :updated_at, Fantasy.Ecto.UnixTimestamp, source: :updatedAt

    has_many :teams, Fantasy.Tournaments.Team, foreign_key: :tournamentId
    has_many :picks, Fantasy.Tournaments.Pick, foreign_key: :tournamentId
    has_one :ideal_pick, Fantasy.Tournaments.IdealPick, foreign_key: :tournamentId
  end

  @doc """
  Changeset for creating a new tournament.
  """
  def create_changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :deadline,
      :title,
      :slug,
      :max_teams,
      :max_price,
      :spreadsheet_url,
      :team_column_name,
      :result_column_name
    ])
    |> validate_required([:deadline, :title, :slug])
    |> unique_constraint(:slug)
    |> validate_number(:max_teams, greater_than: 0, less_than_or_equal_to: 20)
    |> validate_number(:max_price, greater_than: 0)
  end

  @doc """
  Changeset for updating an existing tournament.
  """
  def update_changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :deadline,
      :title,
      :max_teams,
      :max_price,
      :spreadsheet_url,
      :team_column_name,
      :result_column_name
    ])
    |> validate_required([:deadline, :title])
    |> validate_number(:max_teams, greater_than: 0, less_than_or_equal_to: 20)
    |> validate_number(:max_price, greater_than: 0)
  end

  @doc """
  Returns true if the tournament is still open for picks.
  """
  def open?(%__MODULE__{deadline: deadline}) do
    DateTime.compare(DateTime.utc_now(), deadline) == :lt
  end

  def open?(nil), do: false
end

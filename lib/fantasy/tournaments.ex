defmodule Fantasy.Tournaments do
  @moduledoc """
  The Tournaments context handles tournament, team, and pick operations.
  """

  import Ecto.Query
  alias Fantasy.Repo
  alias Fantasy.Tournaments.{Tournament, Team, Pick}

  # ============================================================================
  # Tournament Functions
  # ============================================================================

  @doc """
  Gets a tournament by its slug.

  Returns nil if not found.
  """
  def get_tournament_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Tournament, slug: slug)
  end

  def get_tournament_by_slug(_), do: nil

  @doc """
  Gets a tournament by its slug.

  Raises `Ecto.NoResultsError` if not found.
  """
  def get_tournament_by_slug!(slug) when is_binary(slug) do
    Repo.get_by!(Tournament, slug: slug)
  end

  @doc """
  Gets a tournament by ID.
  """
  def get_tournament(id) do
    Repo.get(Tournament, id)
  end

  @doc """
  Lists all tournaments that are still open (deadline in the future).
  """
  def list_open_tournaments do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    Tournament
    |> where([t], t.deadline > ^now)
    |> order_by([t], asc: t.deadline)
    |> Repo.all()
  end

  @doc """
  Lists all tournaments that are closed (deadline in the past).
  """
  def list_closed_tournaments do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    Tournament
    |> where([t], t.deadline <= ^now)
    |> order_by([t], desc: t.deadline)
    |> Repo.all()
  end

  @doc """
  Creates a new tournament with the given attributes.
  """
  def create_tournament(attrs) do
    now = System.system_time(:millisecond)

    %Tournament{}
    |> Tournament.create_changeset(attrs)
    |> Ecto.Changeset.put_change(:created_at, now)
    |> Ecto.Changeset.put_change(:updated_at, now)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament with the given attributes.
  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    now = System.system_time(:millisecond)

    tournament
    |> Tournament.update_changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_at, now)
    |> Repo.update()
  end

  # ============================================================================
  # Team Functions
  # ============================================================================

  @doc """
  Lists all teams for a tournament.
  """
  def list_teams_for_tournament(tournament_id) do
    Team
    |> where([t], t.tournamentId == ^tournament_id)
    |> order_by([t], asc: t.price, asc: t.name)
    |> Repo.all()
  end

  @doc """
  Gets a team by ID.
  """
  def get_team(id) do
    Repo.get(Team, id)
  end

  @doc """
  Gets multiple teams by IDs.
  """
  def get_teams(ids) when is_list(ids) do
    Team
    |> where([t], t.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Creates a team for a tournament.
  """
  def create_team(attrs) do
    %Team{}
    |> Team.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.
  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates multiple teams for a tournament.
  Expects a list of maps with :name and :price keys.
  """
  def create_teams_for_tournament(tournament_id, teams_data) when is_list(teams_data) do
    Repo.transaction(fn ->
      Enum.map(teams_data, fn team_data ->
        attrs = Map.put(team_data, :tournamentId, tournament_id)

        case create_team(attrs) do
          {:ok, team} -> team
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end)
  end

  # ============================================================================
  # Pick Functions
  # ============================================================================

  @doc """
  Gets a user's pick for a tournament.

  Returns nil if the user hasn't made a pick.
  """
  def get_user_pick(user_id, tournament_id) do
    Pick
    |> where([p], p.userId == ^user_id and p.tournamentId == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Gets a user's pick for a tournament, preloading the selected teams.
  """
  def get_user_pick_with_teams(user_id, tournament_id) do
    case get_user_pick(user_id, tournament_id) do
      nil ->
        nil

      pick ->
        team_ids = Pick.get_team_ids(pick)
        teams = get_teams(team_ids)
        {pick, teams}
    end
  end

  @doc """
  Saves a user's picks for a tournament.

  Uses optimistic locking with the version field to prevent concurrent updates.
  Only allows saving if the tournament is still open.
  """
  def save_picks(user_id, tournament_id, team_ids, expected_version) do
    with {:ok, tournament} <- validate_tournament_open(tournament_id),
         {:ok, _} <- validate_picks(team_ids, tournament) do
      case get_user_pick(user_id, tournament_id) do
        nil ->
          # Create new pick
          %Pick{}
          |> Pick.changeset(%{
            team_ids: Pick.encode_team_ids(team_ids),
            version: 1,
            userId: user_id,
            tournamentId: tournament_id
          })
          |> Repo.insert()

        pick ->
          # Update existing pick with optimistic locking
          if pick.version == expected_version do
            pick
            |> Pick.changeset(%{
              team_ids: Pick.encode_team_ids(team_ids),
              version: expected_version + 1
            })
            |> Repo.update()
          else
            {:error, :version_mismatch}
          end
      end
    end
  end

  defp validate_tournament_open(tournament_id) do
    case get_tournament(tournament_id) do
      nil ->
        {:error, :tournament_not_found}

      tournament ->
        if Tournament.open?(tournament) do
          {:ok, tournament}
        else
          {:error, :tournament_closed}
        end
    end
  end

  defp validate_picks(team_ids, tournament) do
    teams = get_teams(team_ids)

    cond do
      length(team_ids) > tournament.max_teams ->
        {:error, :too_many_teams}

      Enum.sum(Enum.map(teams, & &1.price)) > tournament.max_price ->
        {:error, :price_exceeded}

      true ->
        {:ok, teams}
    end
  end

  @doc """
  Gets all picks for a tournament.
  """
  def list_picks_for_tournament(tournament_id) do
    Pick
    |> where([p], p.tournamentId == ^tournament_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets popular teams for a tournament - teams sorted by how many users picked them.
  Returns a list of maps with team info and pick count.
  """
  def get_popular_teams(tournament_id) do
    picks = list_picks_for_tournament(tournament_id)
    teams = list_teams_for_tournament(tournament_id)

    # Count picks per team
    team_counts =
      picks
      |> Enum.flat_map(&Pick.get_team_ids/1)
      |> Enum.frequencies()

    # Combine with team data
    teams
    |> Enum.map(fn team ->
      %{
        team: team,
        pick_count: Map.get(team_counts, team.id, 0)
      }
    end)
    |> Enum.sort_by(& &1.pick_count, :desc)
  end
end

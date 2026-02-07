defmodule Fantasy.Results do
  @moduledoc """
  The Results context handles tournament results, scoring, and ideal pick calculation.
  """

  import Ecto.Query
  alias Fantasy.Repo
  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.{Pick, IdealPick}

  @doc """
  Gets the tournament results with user rankings.

  Returns a list of maps with user info, selected teams, and total points,
  sorted by points descending.
  """
  def get_tournament_results(tournament_id) do
    picks = Tournaments.list_picks_for_tournament(tournament_id)
    all_teams = Tournaments.list_teams_for_tournament(tournament_id)
    teams_by_id = Map.new(all_teams, &{&1.id, &1})

    picks
    |> Enum.map(fn pick ->
      team_ids = Pick.get_team_ids(pick)
      teams = Enum.map(team_ids, &Map.get(teams_by_id, &1)) |> Enum.reject(&is_nil/1)
      total_points = Enum.sum(Enum.map(teams, & &1.points))

      %{
        user: pick.user,
        teams: teams,
        total_points: total_points
      }
    end)
    |> Enum.sort_by(& &1.total_points, :desc)
    |> add_rankings()
  end

  defp add_rankings(results) do
    results
    |> Enum.with_index(1)
    |> Enum.reduce({[], nil, 0}, fn {result, index}, {acc, prev_points, prev_rank} ->
      rank =
        if result.total_points == prev_points do
          prev_rank
        else
          index
        end

      {[Map.put(result, :rank, rank) | acc], result.total_points, rank}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @doc """
  Gets the ideal pick for a tournament.

  Returns nil if no ideal pick has been calculated.
  """
  def get_ideal_pick(tournament_id) do
    IdealPick
    |> where([ip], ip.tournamentId == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Gets the ideal pick for a tournament with the teams loaded.
  """
  def get_ideal_pick_with_teams(tournament_id) do
    case get_ideal_pick(tournament_id) do
      nil ->
        nil

      ideal_pick ->
        team_ids = IdealPick.get_team_ids(ideal_pick)
        teams = Tournaments.get_teams(team_ids)
        {ideal_pick, teams}
    end
  end

  @doc """
  Calculates and saves the ideal pick for a tournament.

  Uses a knapsack algorithm to find the optimal team selection
  that maximizes points within the price and team count constraints.
  """
  def update_ideal_pick(tournament_id) do
    tournament = Tournaments.get_tournament(tournament_id)
    teams = Tournaments.list_teams_for_tournament(tournament_id)

    {ideal_team_ids, total_points} =
      calculate_ideal_pick(teams, tournament.max_price, tournament.max_teams)

    attrs = %{
      team_ids: IdealPick.encode_team_ids(ideal_team_ids),
      points: total_points,
      tournamentId: tournament_id
    }

    case get_ideal_pick(tournament_id) do
      nil ->
        %IdealPick{}
        |> IdealPick.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> IdealPick.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Calculates the ideal pick using a bounded knapsack algorithm.

  This is a 0/1 knapsack problem with an additional constraint on the number of items.

  ## Parameters
    - teams: List of teams with :id, :price, and :points fields
    - max_price: Maximum total price allowed
    - max_teams: Maximum number of teams allowed

  ## Returns
    - {team_ids, total_points} tuple with the optimal selection
  """
  def calculate_ideal_pick(teams, max_price, max_teams) do
    # Dynamic programming solution for bounded knapsack
    # dp[price][count] = {max_points, team_ids}
    teams = Enum.with_index(teams)

    initial_dp = %{{0, 0} => {0, []}}

    final_dp =
      Enum.reduce(teams, initial_dp, fn {team, _idx}, dp ->
        # For each existing state, try adding this team
        Enum.reduce(dp, dp, fn {{price, count}, {points, ids}}, acc ->
          new_price = price + team.price
          new_count = count + 1
          new_points = points + team.points
          new_ids = [team.id | ids]

          if new_price <= max_price and new_count <= max_teams do
            key = {new_price, new_count}

            case Map.get(acc, key) do
              nil ->
                Map.put(acc, key, {new_points, new_ids})

              {existing_points, _} when new_points > existing_points ->
                Map.put(acc, key, {new_points, new_ids})

              _ ->
                acc
            end
          else
            acc
          end
        end)
      end)

    # Find the best result
    {best_points, best_ids} =
      final_dp
      |> Map.values()
      |> Enum.max_by(fn {points, _} -> points end, fn -> {0, []} end)

    {Enum.reverse(best_ids), best_points}
  end
end

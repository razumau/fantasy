defmodule Fantasy.Stats do
  @moduledoc """
  The Stats context handles tournament metrics and statistics.
  """

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Pick
  alias Fantasy.Results

  @doc """
  Gets team statistics for a tournament.

  Returns a list of teams with pick count and popularity percentage.
  """
  def get_team_stats(tournament_id) do
    picks = Tournaments.list_picks_for_tournament(tournament_id)
    teams = Tournaments.list_teams_for_tournament(tournament_id)
    total_picks = length(picks)

    # Count picks per team
    team_counts =
      picks
      |> Enum.flat_map(&Pick.get_team_ids/1)
      |> Enum.frequencies()

    teams
    |> Enum.map(fn team ->
      pick_count = Map.get(team_counts, team.id, 0)
      popularity = if total_picks > 0, do: pick_count / total_picks * 100, else: 0

      %{
        team: team,
        pick_count: pick_count,
        popularity: Float.round(popularity, 1)
      }
    end)
    |> Enum.sort_by(& &1.team.price)
  end

  @doc """
  Gets tournament metrics including difficulty bias and accuracy.

  ## Metrics calculated:
  - `total_picks`: Number of users who participated
  - `avg_points`: Average points scored by participants
  - `max_points`: Highest points scored
  - `ideal_points`: Points from ideal pick
  - `difficulty_bias`: How much the ideal pick differs from random selection
  - `avg_accuracy`: How close average picks were to ideal (percentage)
  - `price_efficiency`: Points per price unit for ideal pick
  """
  def get_tournament_metrics(tournament_id) do
    tournament = Tournaments.get_tournament(tournament_id)
    results = Results.get_tournament_results(tournament_id)
    teams = Tournaments.list_teams_for_tournament(tournament_id)

    total_picks = length(results)

    if total_picks == 0 do
      %{
        total_picks: 0,
        avg_points: 0,
        max_points: 0,
        ideal_points: 0,
        difficulty_bias: 0,
        avg_accuracy: 0,
        price_efficiency: 0
      }
    else
      points_list = Enum.map(results, & &1.total_points)
      avg_points = Enum.sum(points_list) / total_picks
      max_points = Enum.max(points_list)

      {_, ideal_points} =
        Results.calculate_ideal_pick(teams, tournament.max_price, tournament.max_teams)

      # Calculate random expected points (average of all teams * max_teams)
      total_team_points = Enum.sum(Enum.map(teams, & &1.points))
      avg_team_points = if length(teams) > 0, do: total_team_points / length(teams), else: 0
      random_expected = avg_team_points * tournament.max_teams

      # Difficulty bias: how much better ideal is vs random
      difficulty_bias =
        if random_expected > 0 do
          (ideal_points - random_expected) / random_expected * 100
        else
          0
        end

      # Average accuracy: how close players got to ideal
      avg_accuracy =
        if ideal_points > 0 do
          avg_points / ideal_points * 100
        else
          100
        end

      # Price efficiency
      ideal_pick = Results.get_ideal_pick_with_teams(tournament_id)

      price_efficiency =
        case ideal_pick do
          {_ideal, ideal_teams} ->
            total_price = Enum.sum(Enum.map(ideal_teams, & &1.price))
            if total_price > 0, do: ideal_points / total_price, else: 0

          nil ->
            0
        end

      %{
        total_picks: total_picks,
        avg_points: Float.round(avg_points, 1),
        max_points: max_points,
        ideal_points: ideal_points,
        difficulty_bias: Float.round(difficulty_bias, 1),
        avg_accuracy: Float.round(avg_accuracy, 1),
        price_efficiency: Float.round(price_efficiency, 2)
      }
    end
  end
end

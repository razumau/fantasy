defmodule Fantasy.Fixtures do
  @moduledoc """
  Shared test fixtures for creating users, tournaments, teams, and setting up auth.
  """

  alias Fantasy.Accounts
  alias Fantasy.Tournaments

  @doc """
  Creates a user with unique google_id and email.
  Accepts optional overrides.
  """
  def create_user(attrs \\ %{}) do
    n = System.unique_integer([:positive])

    {:ok, user} =
      Accounts.create_user(
        Map.merge(
          %{
            google_id: "google_#{n}",
            name: "User #{n}",
            email: "user#{n}@example.com"
          },
          attrs
        )
      )

    user
  end

  @doc """
  Creates an open tournament (deadline far in the future).
  Accepts optional overrides.
  """
  def create_tournament(attrs \\ %{}) do
    n = System.unique_integer([:positive])
    future = DateTime.utc_now() |> DateTime.add(7, :day)

    {:ok, tournament} =
      Tournaments.create_tournament(
        Map.merge(
          %{
            title: "Test Tournament #{n}",
            slug: "test-#{n}",
            deadline: future,
            max_teams: 5,
            max_price: 220
          },
          attrs
        )
      )

    tournament
  end

  @doc """
  Creates a team for a tournament.
  Accepts tournament_id and optional overrides.
  """
  def create_team(tournament_id, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    {:ok, team} =
      Tournaments.create_team(
        Map.merge(
          %{
            name: "Team #{n}",
            price: 30,
            points: 25,
            tournamentId: tournament_id
          },
          attrs
        )
      )

    team
  end

  @doc """
  Creates a tournament with 8 teams at varying prices and points.
  Returns {tournament, teams}.
  """
  def setup_tournament_with_teams(tournament_attrs \\ %{}) do
    tournament = create_tournament(tournament_attrs)

    team_data = [
      %{name: "Alpha", price: 30, points: 25},
      %{name: "Bravo", price: 35, points: 30},
      %{name: "Charlie", price: 40, points: 35},
      %{name: "Delta", price: 45, points: 40},
      %{name: "Echo", price: 50, points: 45},
      %{name: "Foxtrot", price: 55, points: 50},
      %{name: "Golf", price: 60, points: 55},
      %{name: "Hotel", price: 65, points: 60}
    ]

    teams =
      Enum.map(team_data, fn data ->
        create_team(tournament.id, data)
      end)

    {tournament, teams}
  end

  @doc """
  Sets up the conn with a logged-in user session.
  Must be used with a conn that has gone through `Phoenix.ConnTest.build_conn/0`.
  """
  def log_in_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
  end
end

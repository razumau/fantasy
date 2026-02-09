defmodule FantasyWeb.TournamentLive.ResultsTest do
  use FantasyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Fantasy.Fixtures

  alias Fantasy.Tournaments

  describe "results page" do
    test "renders without authentication (public route)", %{conn: conn} do
      {tournament, _teams} = setup_tournament_with_teams()

      {:ok, _view, html} = live(conn, ~p"/tournaments/#{tournament.slug}/results")
      assert html =~ tournament.title
    end

    test "shows player names, teams, and points", %{conn: conn} do
      {tournament, teams} = setup_tournament_with_teams()
      user = create_user(%{name: "Alice"})

      # Save picks with first 3 teams
      team_ids = Enum.map(Enum.take(teams, 3), & &1.id)
      {:ok, _} = Tournaments.save_picks(user.id, tournament.id, team_ids, 0)

      {:ok, _view, html} = live(conn, ~p"/tournaments/#{tournament.slug}/results")

      assert html =~ "Alice"

      for team <- Enum.take(teams, 3) do
        assert html =~ team.name
      end
    end

    test "shows 'No picks submitted' for empty tournament", %{conn: conn} do
      {tournament, _teams} = setup_tournament_with_teams()

      {:ok, _view, html} = live(conn, ~p"/tournaments/#{tournament.slug}/results")
      assert html =~ "No picks submitted"
    end

    test "shows player count", %{conn: conn} do
      {tournament, teams} = setup_tournament_with_teams()

      user1 = create_user(%{name: "Bob"})
      user2 = create_user(%{name: "Carol"})

      ids = Enum.map(Enum.take(teams, 2), & &1.id)
      {:ok, _} = Tournaments.save_picks(user1.id, tournament.id, ids, 0)
      {:ok, _} = Tournaments.save_picks(user2.id, tournament.id, ids, 0)

      {:ok, _view, html} = live(conn, ~p"/tournaments/#{tournament.slug}/results")
      assert html =~ "2 players"
    end
  end
end

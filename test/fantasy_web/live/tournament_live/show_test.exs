defmodule FantasyWeb.TournamentLive.ShowTest do
  use FantasyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Fantasy.Fixtures

  alias Fantasy.Tournaments

  describe "show page" do
    setup %{conn: conn} do
      {tournament, teams} = setup_tournament_with_teams()
      user = create_user()
      conn = log_in_user(conn, user)
      %{conn: conn, tournament: tournament, teams: teams, user: user}
    end

    test "renders tournament page with team names", %{
      conn: conn,
      tournament: tournament,
      teams: teams
    } do
      {:ok, view, html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      assert html =~ tournament.title

      for team <- teams do
        assert has_element?(view, "td", team.name)
      end
    end

    test "unauthenticated users can view page with login prompt", %{tournament: tournament} do
      conn = build_conn()
      {:ok, _view, html} = live(conn, ~p"/tournaments/#{tournament.slug}")
      assert html =~ tournament.title
      assert html =~ "Log in"
      refute html =~ "checkbox"
    end

    test "selecting a team updates selection sidebar and total price", %{
      conn: conn,
      tournament: tournament,
      teams: teams
    } do
      {:ok, view, _html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      team = hd(teams)
      view |> element("input[phx-value-id=\"#{team.id}\"]") |> render_click()

      html = render(view)
      assert html =~ "#{team.name} (#{team.price})"
      assert html =~ "Spent #{team.price} points"
    end

    test "deselecting a team removes it from selection", %{
      conn: conn,
      tournament: tournament,
      teams: teams
    } do
      {:ok, view, _html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      team = hd(teams)

      # Select
      view |> element("input[phx-value-id=\"#{team.id}\"]") |> render_click()
      assert render(view) =~ "#{team.name} (#{team.price})"

      # Deselect
      view |> element("input[phx-value-id=\"#{team.id}\"]") |> render_click()
      # After deselecting, should show "No teams selected yet."
      # Process the save message
      render(view)
      assert render(view) =~ "No teams selected yet."
    end

    test "shows error when exceeding max_teams", %{
      conn: conn,
      tournament: tournament,
      teams: teams
    } do
      {:ok, view, _html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      # Select max_teams (5) teams
      first_five = Enum.take(teams, 5)

      for team <- first_five do
        view |> element("input[phx-value-id=\"#{team.id}\"]") |> render_click()
        render(view)
      end

      # Try to select a 6th team
      sixth = Enum.at(teams, 5)
      html = view |> element("input[phx-value-id=\"#{sixth.id}\"]") |> render_click()

      assert html =~ "Too many teams selected"
    end

    test "shows error when exceeding max_price", %{conn: _conn, teams: _teams, user: user} do
      # Create a tournament with low budget
      tournament = create_tournament(%{max_price: 100, max_teams: 5})

      new_teams =
        Enum.map(
          [
            %{name: "Cheap", price: 40, points: 10},
            %{name: "Mid", price: 45, points: 15},
            %{name: "Pricey", price: 50, points: 20}
          ],
          fn data -> create_team(tournament.id, data) end
        )

      conn = log_in_user(build_conn(), user)
      {:ok, view, _html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      # Select Cheap (40) + Mid (45) = 85, within budget
      view |> element("input[phx-value-id=\"#{Enum.at(new_teams, 0).id}\"]") |> render_click()
      render(view)
      view |> element("input[phx-value-id=\"#{Enum.at(new_teams, 1).id}\"]") |> render_click()
      render(view)

      # Select Pricey (50) → 85 + 50 = 135 > 100
      html =
        view |> element("input[phx-value-id=\"#{Enum.at(new_teams, 2).id}\"]") |> render_click()

      assert html =~ "Budget exceeded"
    end

    test "picks are saved to DB after selection", %{
      conn: conn,
      tournament: tournament,
      teams: teams,
      user: user
    } do
      {:ok, view, _html} = live(conn, ~p"/tournaments/#{tournament.slug}")

      team = hd(teams)
      view |> element("input[phx-value-id=\"#{team.id}\"]") |> render_click()

      # Render to process the async {:save_picks, ...} message
      render(view)

      pick = Tournaments.get_user_pick(user.id, tournament.id)
      assert pick != nil
      assert team.id in Fantasy.Tournaments.Pick.get_team_ids(pick)
    end

    test "different users see their own picks", %{
      tournament: tournament,
      teams: teams
    } do
      user1 = create_user()
      user2 = create_user()

      # User1 saves picks
      team_ids1 = [hd(teams).id]
      {:ok, _} = Tournaments.save_picks(user1.id, tournament.id, team_ids1, 0)

      # User2 saves different picks
      team_ids2 = [Enum.at(teams, 2).id]
      {:ok, _} = Tournaments.save_picks(user2.id, tournament.id, team_ids2, 0)

      # User1 sees their own picks
      conn1 = log_in_user(build_conn(), user1)
      {:ok, view1, _html} = live(conn1, ~p"/tournaments/#{tournament.slug}")
      html1 = render(view1)
      assert html1 =~ "#{hd(teams).name} (#{hd(teams).price})"

      # User2 sees their own picks
      conn2 = log_in_user(build_conn(), user2)
      {:ok, view2, _html} = live(conn2, ~p"/tournaments/#{tournament.slug}")
      html2 = render(view2)
      assert html2 =~ "#{Enum.at(teams, 2).name} (#{Enum.at(teams, 2).price})"
    end

    test "closed tournament shows 'Tournament is closed' and disables checkboxes", %{
      user: user,
      teams: _teams
    } do
      past = DateTime.utc_now() |> DateTime.add(-1, :day)
      closed = create_tournament(%{deadline: past})
      _team = create_team(closed.id, %{name: "Closed Team", price: 30, points: 10})

      conn = log_in_user(build_conn(), user)
      {:ok, _view, html} = live(conn, ~p"/tournaments/#{closed.slug}")

      assert html =~ "Tournament is closed"
      assert html =~ "disabled"
    end
  end
end

defmodule Fantasy.TournamentsTest do
  use Fantasy.DataCase

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Pick
  import Fantasy.Fixtures

  describe "save_picks/4" do
    setup do
      {tournament, teams} = setup_tournament_with_teams()
      user = create_user()
      %{tournament: tournament, teams: teams, user: user}
    end

    test "creates a new pick and returns version 1", %{
      tournament: tournament,
      teams: teams,
      user: user
    } do
      team_ids = Enum.map(Enum.take(teams, 3), & &1.id)
      assert {:ok, pick} = Tournaments.save_picks(user.id, tournament.id, team_ids, 0)
      assert pick.version == 1
      assert Pick.get_team_ids(pick) == team_ids
    end

    test "updates existing pick with correct version", %{
      tournament: tournament,
      teams: teams,
      user: user
    } do
      initial_ids = Enum.map(Enum.take(teams, 2), & &1.id)
      {:ok, _pick} = Tournaments.save_picks(user.id, tournament.id, initial_ids, 0)

      new_ids = Enum.map(Enum.take(teams, 3), & &1.id)
      assert {:ok, pick} = Tournaments.save_picks(user.id, tournament.id, new_ids, 1)
      assert pick.version == 2
      assert Pick.get_team_ids(pick) == new_ids
    end

    test "returns :version_mismatch on stale version", %{
      tournament: tournament,
      teams: teams,
      user: user
    } do
      team_ids = Enum.map(Enum.take(teams, 2), & &1.id)
      {:ok, _pick} = Tournaments.save_picks(user.id, tournament.id, team_ids, 0)

      # Try to update with stale version 0 (current is 1)
      new_ids = Enum.map(Enum.take(teams, 3), & &1.id)

      assert {:error, :version_mismatch} =
               Tournaments.save_picks(user.id, tournament.id, new_ids, 0)
    end

    test "rejects picks exceeding max_price", %{tournament: tournament, teams: teams, user: user} do
      # Pick the 5 most expensive teams: 45 + 50 + 55 + 60 + 65 = 275 > 220
      expensive_ids = teams |> Enum.take(-5) |> Enum.map(& &1.id)

      assert {:error, :price_exceeded} =
               Tournaments.save_picks(user.id, tournament.id, expensive_ids, 0)
    end

    test "allows picks exactly at max_price", %{teams: _teams, user: user} do
      # Create tournament with exact budget for specific teams
      # Alpha(30) + Bravo(35) + Charlie(40) + Delta(45) + Echo(50) = 200
      tournament = create_tournament(%{max_price: 200, max_teams: 5})

      # Re-create teams for this tournament
      team_data = [
        %{name: "A", price: 30, points: 10},
        %{name: "B", price: 35, points: 10},
        %{name: "C", price: 40, points: 10},
        %{name: "D", price: 45, points: 10},
        %{name: "E", price: 50, points: 10}
      ]

      new_teams = Enum.map(team_data, fn data -> create_team(tournament.id, data) end)
      all_ids = Enum.map(new_teams, & &1.id)

      assert {:ok, _pick} = Tournaments.save_picks(user.id, tournament.id, all_ids, 0)
    end

    test "rejects picks exceeding max_teams", %{tournament: tournament, teams: teams, user: user} do
      # max_teams is 5, try to pick 6
      six_ids = teams |> Enum.take(6) |> Enum.map(& &1.id)

      assert {:error, :too_many_teams} =
               Tournaments.save_picks(user.id, tournament.id, six_ids, 0)
    end

    test "allows picks exactly at max_teams", %{tournament: tournament, teams: teams, user: user} do
      # max_teams is 5, pick exactly 5 cheapest: 30+35+40+45+50 = 200 <= 220
      five_ids = teams |> Enum.take(5) |> Enum.map(& &1.id)
      assert {:ok, _pick} = Tournaments.save_picks(user.id, tournament.id, five_ids, 0)
    end

    test "rejects picks for closed tournament", %{teams: teams, user: user} do
      past = DateTime.utc_now() |> DateTime.add(-1, :day)
      closed_tournament = create_tournament(%{deadline: past})

      # Create teams for the closed tournament
      closed_teams =
        Enum.map(Enum.take(teams, 2), fn t ->
          create_team(closed_tournament.id, %{name: t.name, price: t.price, points: t.points})
        end)

      team_ids = Enum.map(closed_teams, & &1.id)

      assert {:error, :tournament_closed} =
               Tournaments.save_picks(user.id, closed_tournament.id, team_ids, 0)
    end

    test "different users save and retrieve picks independently", %{
      tournament: tournament,
      teams: teams
    } do
      user1 = create_user()
      user2 = create_user()

      ids1 = Enum.map(Enum.take(teams, 2), & &1.id)
      ids2 = Enum.map(Enum.take(teams, 3), & &1.id)

      {:ok, _} = Tournaments.save_picks(user1.id, tournament.id, ids1, 0)
      {:ok, _} = Tournaments.save_picks(user2.id, tournament.id, ids2, 0)

      pick1 = Tournaments.get_user_pick(user1.id, tournament.id)
      pick2 = Tournaments.get_user_pick(user2.id, tournament.id)

      assert Pick.get_team_ids(pick1) == ids1
      assert Pick.get_team_ids(pick2) == ids2
    end

    test "one user's save does not affect another user's picks", %{
      tournament: tournament,
      teams: teams
    } do
      user1 = create_user()
      user2 = create_user()

      ids1 = Enum.map(Enum.take(teams, 2), & &1.id)
      {:ok, _} = Tournaments.save_picks(user1.id, tournament.id, ids1, 0)

      # User2 saves different picks
      ids2 = Enum.map(Enum.take(teams, 4), & &1.id)
      {:ok, _} = Tournaments.save_picks(user2.id, tournament.id, ids2, 0)

      # User1's picks should be unchanged
      pick1 = Tournaments.get_user_pick(user1.id, tournament.id)
      assert Pick.get_team_ids(pick1) == ids1
    end
  end
end

defmodule Fantasy.ResultsTest do
  use ExUnit.Case, async: true

  alias Fantasy.Results

  defp build_team(price, points) do
    id = :rand.uniform(100_000)
    %{id: id, name: "Team #{id}", price: price, points: points}
  end

  describe "calculate_ideal_pick/3" do
    test "returns empty result when no teams" do
      {ids, points} = Results.calculate_ideal_pick([], 200, 5)
      assert ids == []
      assert points == 0
    end

    test "picks all teams when they fit within constraints" do
      teams = [
        build_team(10, 10),
        build_team(20, 20),
        build_team(30, 30),
        build_team(40, 40)
      ]

      {_ids, points} = Results.calculate_ideal_pick(teams, 100, 4)
      assert points == 100
    end

    test "respects team count limit" do
      teams = [
        build_team(10, 10),
        build_team(20, 20),
        build_team(30, 30),
        build_team(40, 40)
      ]

      {ids, points} = Results.calculate_ideal_pick(teams, 100, 3)
      assert points == 90
      assert length(ids) == 3
    end

    test "respects price limit" do
      teams = [
        build_team(50, 50),
        build_team(50, 40),
        build_team(50, 30),
        build_team(50, 20)
      ]

      {ids, points} = Results.calculate_ideal_pick(teams, 100, 4)
      assert points == 90
      assert length(ids) == 2
    end

    test "returns correct team ids" do
      teams = [
        %{id: 1, name: "Cheap", price: 10, points: 5},
        %{id: 2, name: "Best", price: 50, points: 100},
        %{id: 3, name: "Okay", price: 30, points: 20}
      ]

      {ids, _points} = Results.calculate_ideal_pick(teams, 80, 2)
      assert 2 in ids
    end

    test "medium list with various constraints" do
      teams = [
        build_team(10, 10),
        build_team(10, 15),
        build_team(20, 18),
        build_team(20, 22),
        build_team(20, 32),
        build_team(25, 32),
        build_team(25, 32),
        build_team(35, 32),
        build_team(35, 35),
        build_team(35, 43),
        build_team(40, 32),
        build_team(40, 43),
        build_team(40, 43),
        build_team(45, 43),
        build_team(45, 44),
        build_team(45, 45),
        build_team(50, 34),
        build_team(50, 52),
        build_team(50, 62),
        build_team(55, 50),
        build_team(55, 53),
        build_team(60, 60),
        build_team(60, 61)
      ]

      assert {_, 182} = Results.calculate_ideal_pick(teams, 150, 4)
      assert {_, 207} = Results.calculate_ideal_pick(teams, 180, 4)
      assert {_, 219} = Results.calculate_ideal_pick(teams, 200, 4)
      assert {_, 221} = Results.calculate_ideal_pick(teams, 180, 5)
      assert {_, 234} = Results.calculate_ideal_pick(teams, 200, 5)
      assert {_, 251} = Results.calculate_ideal_pick(teams, 220, 5)
      assert {_, 264} = Results.calculate_ideal_pick(teams, 220, 6)
    end

    test "large list (80+ teams) with 10-team picks" do
      teams = [
        build_team(15, 9),
        build_team(15, 19),
        build_team(15, 12),
        build_team(15, 10),
        build_team(15, 20),
        build_team(15, 18),
        build_team(15, 20),
        build_team(15, 19),
        build_team(15, 10),
        build_team(20, 17),
        build_team(20, 17),
        build_team(20, 25),
        build_team(20, 26),
        build_team(20, 16),
        build_team(20, 13),
        build_team(20, 24),
        build_team(20, 26),
        build_team(20, 26),
        build_team(20, 20),
        build_team(25, 28),
        build_team(25, 25),
        build_team(25, 27),
        build_team(25, 21),
        build_team(25, 18),
        build_team(25, 27),
        build_team(25, 22),
        build_team(25, 26),
        build_team(30, 26),
        build_team(30, 34),
        build_team(30, 32),
        build_team(30, 30),
        build_team(30, 27),
        build_team(30, 28),
        build_team(30, 30),
        build_team(30, 26),
        build_team(35, 35),
        build_team(35, 30),
        build_team(35, 31),
        build_team(35, 33),
        build_team(35, 28),
        build_team(35, 37),
        build_team(40, 40),
        build_team(40, 44),
        build_team(40, 45),
        build_team(40, 41),
        build_team(40, 39),
        build_team(40, 44),
        build_team(40, 35),
        build_team(45, 38),
        build_team(45, 45),
        build_team(45, 46),
        build_team(45, 41),
        build_team(45, 46),
        build_team(45, 45),
        build_team(45, 42),
        build_team(50, 50),
        build_team(50, 45),
        build_team(50, 49),
        build_team(50, 53),
        build_team(50, 54),
        build_team(50, 52),
        build_team(50, 49),
        build_team(50, 52),
        build_team(50, 46),
        build_team(55, 49),
        build_team(55, 58),
        build_team(55, 53),
        build_team(55, 55),
        build_team(55, 58),
        build_team(55, 51),
        build_team(55, 52),
        build_team(55, 56),
        build_team(55, 54),
        build_team(60, 66),
        build_team(60, 63),
        build_team(60, 59),
        build_team(60, 64),
        build_team(60, 57),
        build_team(60, 60),
        build_team(60, 63),
        build_team(60, 61),
        build_team(60, 60)
      ]

      assert {ids1, 410} = Results.calculate_ideal_pick(teams, 360, 10)
      assert length(ids1) == 10

      assert {ids2, 467} = Results.calculate_ideal_pick(teams, 420, 10)
      assert length(ids2) == 10
    end

    test "selected team ids are valid" do
      teams = [
        build_team(20, 32),
        build_team(25, 32),
        build_team(35, 43),
        build_team(40, 43),
        build_team(50, 62),
        build_team(60, 61)
      ]

      {ids, _points} = Results.calculate_ideal_pick(teams, 200, 4)
      team_ids = Enum.map(teams, & &1.id)
      assert Enum.all?(ids, &(&1 in team_ids))
      assert length(ids) == length(Enum.uniq(ids)), "ids should be unique"
    end

    test "single team within budget" do
      teams = [build_team(30, 50)]

      assert {[_], 50} = Results.calculate_ideal_pick(teams, 30, 1)
    end

    test "single team over budget returns empty" do
      teams = [build_team(30, 50)]

      assert {[], 0} = Results.calculate_ideal_pick(teams, 20, 1)
    end
  end
end

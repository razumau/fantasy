defmodule Fantasy.SpreadsheetTest do
  use Fantasy.DataCase, async: true

  alias Fantasy.Spreadsheet

  describe "find_matching_team/2" do
    setup do
      teams = [
        %{id: 1, name: "Arsenal"},
        %{id: 2, name: "Manchester United"},
        %{id: 3, name: "Real Madrid (ESP)"},
        %{id: 4, name: "Bayern Munich"}
      ]

      %{teams: teams}
    end

    test "exact match", %{teams: teams} do
      assert %{id: 1} = Spreadsheet.find_matching_team(teams, "Arsenal")
    end

    test "case-insensitive match", %{teams: teams} do
      assert %{id: 1} = Spreadsheet.find_matching_team(teams, "arsenal")
      assert %{id: 2} = Spreadsheet.find_matching_team(teams, "MANCHESTER UNITED")
    end

    test "match with trimmed whitespace", %{teams: teams} do
      assert %{id: 1} = Spreadsheet.find_matching_team(teams, "  Arsenal  ")
    end

    test "match DB team ignoring trailing parenthetical", %{teams: teams} do
      assert %{id: 3} = Spreadsheet.find_matching_team(teams, "Real Madrid")
    end

    test "match spreadsheet name ignoring trailing parenthetical", %{teams: teams} do
      assert %{id: 4} = Spreadsheet.find_matching_team(teams, "Bayern Munich (GER)")
    end

    test "returns nil when no match", %{teams: teams} do
      assert is_nil(Spreadsheet.find_matching_team(teams, "Nonexistent FC"))
    end
  end

  describe "fetch_results/1" do
    test "returns error when tournament not found" do
      assert {:error, "Tournament not found"} = Spreadsheet.fetch_results(-1)
    end

    test "returns error when spreadsheet not configured" do
      tournament = Fantasy.Fixtures.create_tournament()

      assert {:error, "Spreadsheet not configured for this tournament"} =
               Spreadsheet.fetch_results(tournament.id)
    end
  end
end

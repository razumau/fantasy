defmodule Fantasy.Spreadsheet do
  @moduledoc """
  Fetches tournament results from a public Google Spreadsheet (XLSX export).
  """

  alias Fantasy.Tournaments
  alias Fantasy.Results

  @doc """
  Fetches results from the tournament's configured spreadsheet URL,
  matches team names to DB teams, and updates their points.

  Returns `{:ok, count}` with the number of updated teams, or `{:error, reason}`.
  """
  def fetch_results(tournament_id) do
    tournament = Tournaments.get_tournament(tournament_id)

    with {:ok, tournament} <- validate_config(tournament),
         {:ok, body} <- download(tournament.spreadsheet_url),
         {:ok, rows} <- parse_xlsx(body),
         {:ok, count} <- apply_results(tournament, rows) do
      Results.update_ideal_pick(tournament_id)
      {:ok, count}
    end
  end

  defp validate_config(nil), do: {:error, "Tournament not found"}

  defp validate_config(tournament) do
    if tournament.spreadsheet_url && tournament.spreadsheet_url != "" &&
         tournament.team_column_name && tournament.team_column_name != "" &&
         tournament.result_column_name && tournament.result_column_name != "" do
      {:ok, tournament}
    else
      {:error, "Spreadsheet not configured for this tournament"}
    end
  end

  defp download(url, redirects_left \\ 5) do
    url = to_export_url(url)
    request = Finch.build(:get, url)

    case Finch.request(request, Fantasy.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{status: status, headers: headers}}
      when status in [301, 302, 303, 307, 308] and redirects_left > 0 ->
        case List.keyfind(headers, "location", 0) do
          {_, location} -> download(location, redirects_left - 1)
          nil -> {:error, "Redirect with no location header"}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Failed to fetch spreadsheet (HTTP #{status})"}

      {:error, reason} ->
        {:error, "Failed to fetch spreadsheet: #{inspect(reason)}"}
    end
  end

  defp parse_xlsx(body) do
    tmp_path =
      Path.join(System.tmp_dir!(), "fantasy_spreadsheet_#{:rand.uniform(1_000_000)}.xlsx")

    try do
      File.write!(tmp_path, body)

      case Xlsxir.multi_extract(tmp_path) do
        [{:ok, first_table} | rest] ->
          rows = Xlsxir.get_list(first_table)
          Xlsxir.close(first_table)
          Enum.each(rest, fn {:ok, ref} -> Xlsxir.close(ref) end)
          {:ok, rows}

        {:error, reason} ->
          {:error, "Failed to parse spreadsheet: #{inspect(reason)}"}
      end
    after
      File.rm(tmp_path)
    end
  end

  defp apply_results(tournament, [header | data_rows]) do
    team_col_idx = Enum.find_index(header, &(&1 == tournament.team_column_name))
    result_col_idx = Enum.find_index(header, &(&1 == tournament.result_column_name))

    if is_nil(team_col_idx) or is_nil(result_col_idx) do
      {:error, "Could not find team or result column in spreadsheet"}
    else
      teams = Tournaments.list_teams_for_tournament(tournament.id)

      count =
        Enum.reduce(data_rows, 0, fn row, acc ->
          team_name = Enum.at(row, team_col_idx)
          points = Enum.at(row, result_col_idx)

          if is_binary(team_name) && points != nil do
            case find_matching_team(teams, team_name) do
              nil ->
                acc

              team ->
                points_value = if is_number(points), do: round(points), else: parse_points(points)

                if points_value do
                  Tournaments.update_team(team, %{points: points_value})
                  acc + 1
                else
                  acc
                end
            end
          else
            acc
          end
        end)

      {:ok, count}
    end
  end

  defp apply_results(_tournament, _rows) do
    {:error, "Spreadsheet is empty"}
  end

  defp parse_points(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_points(_), do: nil

  @doc """
  Finds a matching team by name using fuzzy matching.

  Matching strategy (in order):
  1. Exact match (case-insensitive, trimmed)
  2. DB team name with trailing parenthetical removed matches spreadsheet name
  3. Spreadsheet name with trailing parenthetical removed matches DB team name
  """
  def find_matching_team(teams, spreadsheet_name) do
    normalized = spreadsheet_name |> String.trim() |> String.downcase()

    Enum.find(teams, fn team ->
      team.name |> String.trim() |> String.downcase() == normalized
    end) ||
      Enum.find(teams, fn team ->
        team.name |> strip_parenthetical() |> String.trim() |> String.downcase() == normalized
      end) ||
      Enum.find(teams, fn team ->
        base = normalized |> strip_parenthetical()
        team.name |> String.trim() |> String.downcase() == base
      end)
  end

  defp strip_parenthetical(name) do
    String.replace(name, ~r/\s*\([^)]*\)\s*$/, "")
  end

  @google_sheets_regex ~r{^https?://docs\.google\.com/spreadsheets/d/([^/]+)(?:/.*)?$}

  defp to_export_url(url) do
    case Regex.run(@google_sheets_regex, url) do
      [_, sheet_id] ->
        "https://docs.google.com/spreadsheets/d/#{sheet_id}/export?format=xlsx"

      nil ->
        url
    end
  end
end

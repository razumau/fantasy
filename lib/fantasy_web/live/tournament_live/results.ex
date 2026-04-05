defmodule FantasyWeb.TournamentLive.Results do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Tournament
  alias Fantasy.Results

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    results = Results.get_tournament_results(tournament.id)
    ideal_pick = Results.get_ideal_pick_with_teams(tournament.id)
    teams = Tournaments.list_teams_for_tournament(tournament.id)

    sorted_by_value =
      teams
      |> Enum.filter(&(&1.points > 0))
      |> Enum.sort_by(&(&1.points - &1.price), :desc)

    total_players = length(results)

    pick_counts =
      results
      |> Enum.flat_map(fn r -> Enum.map(r.teams, & &1.id) end)
      |> Enum.frequencies()

    annotate = fn team_list ->
      Enum.map(team_list, fn team ->
        count = Map.get(pick_counts, team.id, 0)
        pct = if total_players > 0, do: count / total_players * 100, else: 0.0
        Map.put(team, :pick_pct, pct)
      end)
    end

    overachievers = sorted_by_value |> Enum.take(5) |> annotate.()
    underachievers = sorted_by_value |> Enum.reverse() |> Enum.take(5) |> annotate.()

    {:ok,
     assign(socket,
       page_title: "#{tournament.title} — Results",
       tournament: tournament,
       results: results,
       ideal_pick: ideal_pick,
       overachievers: overachievers,
       underachievers: underachievers,
       is_open: Tournament.open?(tournament)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-3xl font-bold">{@tournament.title}</h1>
      </div>

      <%= if @ideal_pick do %>
        <% {ideal, teams} = @ideal_pick %>
        <div class="border border-base-300 bg-base-200 rounded-lg p-4">
          <p>
            The maximum possible score was {ideal.points} points. You could get there with these teams:
          </p>
          <div class="mt-2 space-y-1">
            <%= for team <- teams do %>
              <p>{team.name} ({team.price}) — {team.points}</p>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @overachievers != [] do %>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="border border-base-300 bg-base-200 rounded-lg p-4">
            <p class="mb-2">We underrated these teams:</p>
            <div class="space-y-1">
              <%= for {team, idx} <- Enum.with_index(@overachievers) do %>
                <p>
                  {team.name}: {team.price} → {team.points}
                  (<%= if idx == 0 do %>picked by {format_pct(team.pick_pct)} of players<% else %>{format_pct(team.pick_pct)}<% end %>)
                </p>
              <% end %>
            </div>
          </div>
          <div class="border border-base-300 bg-base-200 rounded-lg p-4">
            <p class="mb-2">We expected more from these teams:</p>
            <div class="space-y-1">
              <%= for {team, idx} <- Enum.with_index(@underachievers) do %>
                <p>
                  {team.name}: {team.price} → {team.points}
                  (<%= if idx == 0 do %>picked by {format_pct(team.pick_pct)} of players<% else %>{format_pct(team.pick_pct)}<% end %>)
                </p>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <div class="text-center space-y-1 text-sm">
        <p>{length(@results)} {if length(@results) > 1, do: "players", else: "player"}</p>
        <%= if @is_open do %>
          <p>
            <.link
              navigate={~p"/tournaments/#{@tournament.slug}"}
              class="link link-primary"
            >
              Pick teams
            </.link>
          </p>
        <% end %>
        <p>
          <.link
            navigate={~p"/tournaments/#{@tournament.slug}/popular"}
            class="link link-primary"
          >
            What are the most popular teams?
          </.link>
        </p>
        <%= if @current_user && @current_user.is_admin do %>
          <p>
            <.link
              navigate={~p"/tournaments/#{@tournament.slug}/edit"}
              class="link link-primary"
            >
              Edit this tournament
            </.link>
          </p>
        <% end %>
      </div>

      <%= if Enum.empty?(@results) do %>
        <p class="text-base-content/60">No picks submitted for this tournament.</p>
      <% else %>
        <div class="card bg-base-200 overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>#</th>
                <th>Player</th>
                <th>Points</th>
                <th>Picked Teams</th>
              </tr>
            </thead>
            <tbody>
              <%= for result <- @results do %>
                <tr class={row_class(result, @current_user)}>
                  <td class="font-bold align-middle">{result.rank}</td>
                  <td class="align-middle">{result.user.name}</td>
                  <td class="align-middle">{result.total_points}</td>
                  <td>
                    <div class="space-y-1">
                      <%= for team <- result.teams do %>
                        <p>{team.name} ({team.price}) — {team.points}</p>
                      <% end %>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp row_class(result, current_user) do
    cond do
      result.rank in [1, 2, 3] -> rank_class(result.rank)
      current_user && result.user.id == current_user.id -> "bg-primary/10"
      true -> ""
    end
  end

  defp format_pct(pct) do
    :erlang.float_to_binary(pct, decimals: 2) <> "%"
  end

  defp rank_class(1), do: "bg-yellow-500/20"
  defp rank_class(2), do: "bg-gray-400/20"
  defp rank_class(3), do: "bg-amber-700/20"
end

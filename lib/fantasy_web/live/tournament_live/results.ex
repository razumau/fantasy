defmodule FantasyWeb.TournamentLive.Results do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Results

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    results = Results.get_tournament_results(tournament.id)
    ideal_pick = Results.get_ideal_pick_with_teams(tournament.id)

    {:ok,
     assign(socket,
       page_title: "#{tournament.title} - Results",
       tournament: tournament,
       results: results,
       ideal_pick: ideal_pick
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold">{@tournament.title}</h1>
          <p class="text-base-content/60">Results</p>
        </div>
        <div class="flex gap-2">
          <.link navigate={~p"/tournaments/#{@tournament.slug}/popular"} class="btn btn-ghost btn-sm">
            Popular Picks
          </.link>
          <.link navigate={~p"/tournaments/#{@tournament.slug}/stats"} class="btn btn-ghost btn-sm">
            Stats
          </.link>
        </div>
      </div>

      <%= if @ideal_pick do %>
        <div class="card bg-primary/10">
          <div class="card-body">
            <h2 class="card-title">Ideal Pick</h2>
            <% {ideal, teams} = @ideal_pick %>
            <div class="flex flex-wrap gap-2">
              <%= for team <- teams do %>
                <span class="badge badge-primary badge-lg">{team.name}</span>
              <% end %>
            </div>
            <p class="mt-2 font-bold">Total Points: {ideal.points}</p>
          </div>
        </div>
      <% end %>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Rankings</h2>

          <%= if Enum.empty?(@results) do %>
            <p class="text-base-content/60">No picks submitted for this tournament.</p>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Rank</th>
                    <th>Player</th>
                    <th>Teams</th>
                    <th class="text-right">Points</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for result <- @results do %>
                    <tr class={rank_class(result.rank)}>
                      <td class="font-bold">{result.rank}</td>
                      <td>{result.user.name}</td>
                      <td>
                        <div class="flex flex-wrap gap-1">
                          <%= for team <- result.teams do %>
                            <span class="badge badge-ghost badge-sm">{team.name}</span>
                          <% end %>
                        </div>
                      </td>
                      <td class="text-right font-mono">{result.total_points}</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp rank_class(1), do: "bg-yellow-500/20"
  defp rank_class(2), do: "bg-gray-400/20"
  defp rank_class(3), do: "bg-amber-700/20"
  defp rank_class(_), do: ""
end

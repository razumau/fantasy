defmodule FantasyWeb.TournamentLive.Stats do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Stats

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    team_stats = Stats.get_team_stats(tournament.id)
    metrics = Stats.get_tournament_metrics(tournament.id)

    {:ok,
     assign(socket,
       page_title: "#{tournament.title} - Stats",
       tournament: tournament,
       team_stats: team_stats,
       metrics: metrics
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold">{@tournament.title}</h1>
          <p class="text-base-content/60">Statistics</p>
        </div>
        <div class="flex gap-2">
          <.link navigate={~p"/tournaments/#{@tournament.slug}/results"} class="btn btn-ghost btn-sm">
            Results
          </.link>
          <.link navigate={~p"/tournaments/#{@tournament.slug}/popular"} class="btn btn-ghost btn-sm">
            Popular
          </.link>
        </div>
      </div>

      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Participants</div>
          <div class="stat-value">{@metrics.total_picks}</div>
        </div>
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Avg Points</div>
          <div class="stat-value">{@metrics.avg_points}</div>
        </div>
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Max Points</div>
          <div class="stat-value">{@metrics.max_points}</div>
        </div>
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Ideal Points</div>
          <div class="stat-value">{@metrics.ideal_points}</div>
        </div>
      </div>

      <div class="grid md:grid-cols-3 gap-4">
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Difficulty Bias</div>
          <div class="stat-value text-lg">{@metrics.difficulty_bias}%</div>
          <div class="stat-desc">How much ideal beats random</div>
        </div>
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Avg Accuracy</div>
          <div class="stat-value text-lg">{@metrics.avg_accuracy}%</div>
          <div class="stat-desc">Avg points vs ideal</div>
        </div>
        <div class="stat bg-base-200 rounded-lg">
          <div class="stat-title">Price Efficiency</div>
          <div class="stat-value text-lg">{@metrics.price_efficiency}</div>
          <div class="stat-desc">Points per price unit (ideal)</div>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Team Statistics</h2>

          <%= if Enum.empty?(@team_stats) do %>
            <p class="text-base-content/60">No data available.</p>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Team</th>
                    <th class="text-right">Price</th>
                    <th class="text-right">Points</th>
                    <th class="text-right">Picks</th>
                    <th class="text-right">Popularity</th>
                    <th class="text-right">Value</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for %{team: team, pick_count: count, popularity: pop} <- @team_stats do %>
                    <tr>
                      <td class="font-medium">{team.name}</td>
                      <td class="text-right">{team.price}</td>
                      <td class="text-right">{team.points}</td>
                      <td class="text-right">{count}</td>
                      <td class="text-right">{pop}%</td>
                      <td class="text-right font-mono">{value_ratio(team)}</td>
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

  defp value_ratio(%{price: price, points: points}) when price > 0 do
    Float.round(points / price, 2)
  end

  defp value_ratio(_), do: 0
end

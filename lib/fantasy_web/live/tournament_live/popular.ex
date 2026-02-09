defmodule FantasyWeb.TournamentLive.Popular do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    popular_teams = Tournaments.get_popular_teams(tournament.id)
    total_picks = length(Tournaments.list_picks_for_tournament(tournament.id))

    {:ok,
     assign(socket,
       page_title: "#{tournament.title} — Popular Picks",
       tournament: tournament,
       popular_teams: popular_teams,
       total_picks: total_picks
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold">{@tournament.title}</h1>
          <p class="text-base-content/60">Popular Picks ({@total_picks} participants)</p>
        </div>
        <div class="flex gap-2">
          <.link navigate={~p"/tournaments/#{@tournament.slug}/results"} class="btn btn-ghost btn-sm">
            Results
          </.link>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Teams by Popularity</h2>

          <%= if Enum.empty?(@popular_teams) do %>
            <p class="text-base-content/60">No picks submitted for this tournament.</p>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Team</th>
                    <th class="text-right">Price</th>
                    <th class="text-right">Points</th>
                    <th class="text-right">Picks</th>
                    <th>Popularity</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for %{team: team, pick_count: count} <- @popular_teams do %>
                    <tr>
                      <td class="font-medium">{team.name}</td>
                      <td class="text-right">{team.price}</td>
                      <td class="text-right">{team.points}</td>
                      <td class="text-right">{count}</td>
                      <td>
                        <div class="flex items-center gap-2">
                          <progress
                            class="progress progress-primary w-24"
                            value={count}
                            max={@total_picks}
                          />
                          <span class="text-sm">
                            {percentage(count, @total_picks)}%
                          </span>
                        </div>
                      </td>
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

  defp percentage(_, 0), do: 0
  defp percentage(count, total), do: round(count / total * 100)
end

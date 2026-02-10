defmodule FantasyWeb.TournamentLive.Popular do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Tournament

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    popular_teams = Tournaments.get_popular_teams(tournament.id)
    total_picks = length(Tournaments.list_picks_for_tournament(tournament.id))
    teams = Tournaments.list_teams_for_tournament(tournament.id)
    has_points = Enum.any?(teams, fn team -> team.points > 0 end)

    {:ok,
     assign(socket,
       page_title: "#{tournament.title} — Popular Picks",
       tournament: tournament,
       popular_teams: popular_teams,
       total_picks: total_picks,
       has_points: has_points,
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

      <div class="text-center space-y-1 text-sm">
        <p>{@total_picks} participants</p>
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
            navigate={~p"/tournaments/#{@tournament.slug}/results"}
            class="link link-primary"
          >
            {if @has_points, do: "See results", else: "See picks by other players"}
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

      <%= if Enum.empty?(@popular_teams) do %>
        <p class="text-base-content/60">No picks submitted for this tournament.</p>
      <% else %>
        <div class="card bg-base-200 overflow-x-auto">
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
    """
  end

  defp percentage(_, 0), do: 0
  defp percentage(count, total), do: round(count / total * 100)
end

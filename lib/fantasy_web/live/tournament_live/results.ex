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
       page_title: "#{tournament.title} — Results",
       tournament: tournament,
       results: results,
       ideal_pick: ideal_pick
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

      <div class="text-center space-y-1 text-sm">
        <p>{length(@results)} players</p>
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
                <tr class={rank_class(result.rank)}>
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

  defp rank_class(1), do: "bg-yellow-500/20"
  defp rank_class(2), do: "bg-gray-400/20"
  defp rank_class(3), do: "bg-amber-700/20"
  defp rank_class(_), do: ""
end

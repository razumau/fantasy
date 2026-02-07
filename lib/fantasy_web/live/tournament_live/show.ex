defmodule FantasyWeb.TournamentLive.Show do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.{Tournament, Pick}

  on_mount {FantasyWeb.Live.Hooks, :require_auth}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    teams = Tournaments.list_teams_for_tournament(tournament.id)

    {version, selected_ids} =
      case Tournaments.get_user_pick(socket.assigns.current_user.id, tournament.id) do
        nil -> {0, MapSet.new()}
        pick -> {pick.version, MapSet.new(Pick.get_team_ids(pick))}
      end

    selected_teams = Enum.filter(teams, &MapSet.member?(selected_ids, &1.id))
    total_price = Enum.sum(Enum.map(selected_teams, & &1.price))
    has_points = Enum.any?(teams, fn team -> team.points > 0 end)

    {:ok,
     assign(socket,
       page_title: tournament.title,
       tournament: tournament,
       teams: teams,
       selected_ids: selected_ids,
       selected_teams: selected_teams,
       total_price: total_price,
       version: version,
       is_open: Tournament.open?(tournament),
       has_points: has_points,
       saving: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("toggle_team", %{"id" => id_str}, socket) do
    team_id = String.to_integer(id_str)

    %{tournament: tournament, teams: teams, selected_ids: selected_ids, version: version} =
      socket.assigns

    new_selected_ids =
      if MapSet.member?(selected_ids, team_id) do
        MapSet.delete(selected_ids, team_id)
      else
        MapSet.put(selected_ids, team_id)
      end

    selected_teams = Enum.filter(teams, &MapSet.member?(new_selected_ids, &1.id))
    total_price = Enum.sum(Enum.map(selected_teams, & &1.price))

    # Validate constraints
    error =
      cond do
        length(selected_teams) > tournament.max_teams ->
          "Too many teams selected (max #{tournament.max_teams})"

        total_price > tournament.max_price ->
          "Budget exceeded (max #{tournament.max_price})"

        true ->
          nil
      end

    if error do
      {:noreply, assign(socket, error: error)}
    else
      # Save picks async
      socket =
        socket
        |> assign(
          selected_ids: new_selected_ids,
          selected_teams: selected_teams,
          total_price: total_price,
          saving: true,
          error: nil
        )

      send(self(), {:save_picks, MapSet.to_list(new_selected_ids), version})
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:save_picks, team_ids, expected_version}, socket) do
    %{current_user: user, tournament: tournament} = socket.assigns

    case Tournaments.save_picks(user.id, tournament.id, team_ids, expected_version) do
      {:ok, pick} ->
        {:noreply, assign(socket, version: pick.version, saving: false)}

      {:error, :version_mismatch} ->
        {:noreply,
         socket
         |> assign(saving: false, error: "Your picks were updated elsewhere. Please refresh.")
         |> put_flash(:error, "Concurrent update detected. Please refresh the page.")}

      {:error, :tournament_closed} ->
        {:noreply,
         socket
         |> assign(saving: false, is_open: false)
         |> put_flash(:error, "Tournament is now closed.")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(saving: false)
         |> put_flash(:error, "Failed to save picks. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-3xl font-bold">{@tournament.title}</h1>
      </div>

      <%= if @error do %>
        <div class="alert alert-error">
          <span>{@error}</span>
        </div>
      <% end %>

      <div class="grid lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2">
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th></th>
                  <th>Team</th>
                  <th class="text-right">Price</th>
                  <%= if @has_points do %>
                    <th class="text-right">Points</th>
                  <% end %>
                </tr>
              </thead>
              <tbody>
                <%= for team <- @teams do %>
                  <tr class={if MapSet.member?(@selected_ids, team.id), do: "bg-primary/10"}>
                    <td>
                      <input
                        type="checkbox"
                        class="checkbox checkbox-primary"
                        checked={MapSet.member?(@selected_ids, team.id)}
                        disabled={not @is_open}
                        phx-click="toggle_team"
                        phx-value-id={team.id}
                      />
                    </td>
                    <td>{team.name}</td>
                    <td class="text-right">{team.price}</td>
                    <%= if @has_points do %>
                      <td class="text-right">{team.points}</td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

        <div>
          <div class="sticky top-4 space-y-4">
            <h2 class="text-xl font-bold">Your Selection</h2>

            <div class="text-sm space-y-1">
              <p>
                Select up to {@tournament.max_teams} teams. Your result is the sum of their points.
              </p>
              <p>
                <%= if @is_open do %>
                  You can change your picks until {format_deadline(@tournament.deadline)} ({time_until_deadline(
                    @tournament.deadline
                  )} left).
                <% else %>
                  Tournament is closed.
                <% end %>
              </p>
            </div>

            <div class="divider my-1"></div>

            <div class="text-sm">
              <p>
                Spent {@total_price} points, {@tournament.max_price - @total_price} remaining.
              </p>
              <progress
                class="progress progress-primary w-full mt-1"
                value={@total_price}
                max={@tournament.max_price}
              >
              </progress>
            </div>

            <%= if @saving do %>
              <div class="text-sm text-base-content/60">
                <span class="loading loading-spinner loading-xs"></span> Saving...
              </div>
            <% end %>

            <%= if Enum.empty?(@selected_teams) do %>
              <p class="text-base-content/60">No teams selected yet.</p>
            <% else %>
              <div class="text-sm space-y-1">
                <%= for team <- @selected_teams do %>
                  <p>{team.name} ({team.price})</p>
                <% end %>
              </div>
              <%= if @has_points do %>
                <div class="pt-2 border-t border-base-300">
                  <div class="flex justify-between font-bold text-sm">
                    <span>Total Points</span>
                    <span>{Enum.sum(Enum.map(@selected_teams, & &1.points))}</span>
                  </div>
                </div>
              <% end %>
            <% end %>

            <div class="divider my-1"></div>

            <div class="text-sm space-y-1">
              <p>
                <.link
                  navigate={~p"/tournaments/#{@tournament.slug}/results"}
                  class="link link-primary"
                >
                  See picks by other players.
                </.link>
              </p>
              <p>
                <.link
                  navigate={~p"/tournaments/#{@tournament.slug}/popular"}
                  class="link link-primary"
                >
                  What are the most popular teams?
                </.link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_deadline(deadline) when is_struct(deadline, DateTime) do
    Calendar.strftime(deadline, "%H:%M on %d.%m.%Y")
  end

  defp format_deadline(_), do: "N/A"

  defp time_until_deadline(deadline) when is_struct(deadline, DateTime) do
    diff_seconds = DateTime.diff(deadline, DateTime.utc_now(), :second)

    cond do
      diff_seconds <= 0 -> "no time"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} minutes"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)} hours"
      diff_seconds < 86400 * 30 -> "#{div(diff_seconds, 86400)} days"
      true -> "more than a month"
    end
  end

  defp time_until_deadline(_), do: ""
end

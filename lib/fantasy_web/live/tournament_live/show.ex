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
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold">{@tournament.title}</h1>
          <p class="text-base-content/60">
            <%= if @is_open do %>
              Deadline: {format_deadline(@tournament.deadline)}
            <% else %>
              <span class="text-error">Tournament closed</span>
            <% end %>
          </p>
        </div>
        <div class="text-right">
          <.link navigate={~p"/tournaments/#{@tournament.slug}/results"} class="btn btn-ghost btn-sm">
            View Results
          </.link>
        </div>
      </div>

      <%= if @error do %>
        <div class="alert alert-error">
          <span>{@error}</span>
        </div>
      <% end %>

      <div class="grid lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2">
          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title">Available Teams</h2>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th></th>
                      <th>Team</th>
                      <th class="text-right">Price</th>
                      <th class="text-right">Points</th>
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
                        <td class="text-right">{team.points}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div>
          <div class="card bg-base-200 sticky top-4">
            <div class="card-body">
              <h2 class="card-title">Your Selection</h2>

              <div class="stats stats-vertical shadow">
                <div class="stat">
                  <div class="stat-title">Teams</div>
                  <div class="stat-value text-lg">
                    {length(@selected_teams)} / {@tournament.max_teams}
                  </div>
                </div>
                <div class="stat">
                  <div class="stat-title">Budget Used</div>
                  <div class={"stat-value text-lg #{if @total_price > @tournament.max_price, do: "text-error"}"}>
                    {@total_price} / {@tournament.max_price}
                  </div>
                </div>
              </div>

              <%= if @saving do %>
                <div class="mt-2 text-sm text-base-content/60">
                  <span class="loading loading-spinner loading-xs"></span> Saving...
                </div>
              <% end %>

              <%= if Enum.empty?(@selected_teams) do %>
                <p class="text-base-content/60 mt-4">No teams selected yet.</p>
              <% else %>
                <ul class="mt-4 space-y-2">
                  <%= for team <- @selected_teams do %>
                    <li class="flex justify-between items-center p-2 bg-base-300 rounded">
                      <span>{team.name}</span>
                      <span class="badge badge-ghost">{team.price}</span>
                    </li>
                  <% end %>
                </ul>
                <div class="mt-4 pt-4 border-t border-base-300">
                  <div class="flex justify-between font-bold">
                    <span>Total Points</span>
                    <span>{Enum.sum(Enum.map(@selected_teams, & &1.points))}</span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_deadline(deadline) when is_struct(deadline, DateTime) do
    Calendar.strftime(deadline, "%b %d, %Y %H:%M")
  end

  defp format_deadline(_), do: "N/A"
end

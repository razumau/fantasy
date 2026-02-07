defmodule FantasyWeb.TournamentLive.Edit do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Tournament
  alias Fantasy.Results

  on_mount {FantasyWeb.Live.Hooks, :require_auth}
  on_mount {FantasyWeb.Live.Hooks, :require_admin}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_by_slug!(slug)
    teams = Tournaments.list_teams_for_tournament(tournament.id)
    changeset = Tournament.update_changeset(tournament, %{})

    {:ok,
     assign(socket,
       page_title: "Edit #{tournament.title}",
       tournament: tournament,
       teams: teams,
       changeset: changeset
     )}
  end

  @impl true
  def handle_event("validate", %{"tournament" => params}, socket) do
    changeset =
      socket.assigns.tournament
      |> Tournament.update_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"tournament" => params}, socket) do
    params = convert_deadline(params)

    case Tournaments.update_tournament(socket.assigns.tournament, params) do
      {:ok, tournament} ->
        {:noreply,
         socket
         |> assign(tournament: tournament)
         |> put_flash(:info, "Tournament updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("save_all_teams", %{"teams" => teams_params}, socket) do
    teams = socket.assigns.teams

    Enum.each(teams_params, fn {id_str, params} ->
      team = Enum.find(teams, &(&1.id == String.to_integer(id_str)))
      if team, do: Tournaments.update_team(team, params)
    end)

    teams = Tournaments.list_teams_for_tournament(socket.assigns.tournament.id)
    {:noreply, socket |> assign(teams: teams) |> put_flash(:info, "Teams saved.")}
  end

  def handle_event("save_all_teams", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_team", _, socket) do
    tournament = socket.assigns.tournament

    case Tournaments.create_team(%{
           name: "New Team",
           price: 10,
           points: 0,
           tournamentId: tournament.id
         }) do
      {:ok, _} ->
        teams = Tournaments.list_teams_for_tournament(tournament.id)
        {:noreply, assign(socket, teams: teams)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add team.")}
    end
  end

  @impl true
  def handle_event("delete_team", %{"id" => id}, socket) do
    team = Enum.find(socket.assigns.teams, &(&1.id == String.to_integer(id)))

    if team do
      case Tournaments.delete_team(team) do
        {:ok, _} ->
          teams = Tournaments.list_teams_for_tournament(socket.assigns.tournament.id)
          {:noreply, assign(socket, teams: teams)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete team.")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("calculate_ideal", _, socket) do
    case Results.update_ideal_pick(socket.assigns.tournament.id) do
      {:ok, ideal} ->
        {:noreply, put_flash(socket, :info, "Ideal pick calculated: #{ideal.points} points")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to calculate ideal pick.")}
    end
  end

  defp convert_deadline(%{"deadline" => deadline_str} = params) when is_binary(deadline_str) do
    case DateTime.from_iso8601(deadline_str <> ":00Z") do
      {:ok, dt, _} -> Map.put(params, "deadline", DateTime.to_unix(dt, :millisecond))
      _ -> params
    end
  end

  defp convert_deadline(params), do: params

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold">Edit Tournament</h1>
        <.link navigate={~p"/tournaments/#{@tournament.slug}"} class="btn btn-ghost btn-sm">
          View Tournament
        </.link>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Tournament Details</h2>

          <.form for={@changeset} phx-change="validate" phx-submit="save">
            <fieldset class="fieldset">
              <legend class="fieldset-legend">Title</legend>
              <input
                type="text"
                name="tournament[title]"
                value={@tournament.title}
                class="input input-bordered w-full"
                required
              />

              <legend class="fieldset-legend">Max Teams</legend>
              <input
                type="number"
                name="tournament[max_teams]"
                value={@tournament.max_teams}
                class="input input-bordered w-full"
                min="1"
                max="20"
                required
              />

              <legend class="fieldset-legend">Max Price</legend>
              <input
                type="number"
                name="tournament[max_price]"
                value={@tournament.max_price}
                class="input input-bordered w-full"
                min="1"
                required
              />

              <legend class="fieldset-legend">Deadline</legend>
              <input
                type="datetime-local"
                name="tournament[deadline]"
                value={format_datetime_local(@tournament.deadline)}
                class="input input-bordered w-full"
                required
              />

              <legend class="fieldset-legend">Spreadsheet URL</legend>
              <input
                type="url"
                name="tournament[spreadsheet_url]"
                value={@tournament.spreadsheet_url}
                class="input input-bordered w-full"
              />

              <legend class="fieldset-legend">Team Column Name</legend>
              <input
                type="text"
                name="tournament[team_column_name]"
                value={@tournament.team_column_name}
                class="input input-bordered w-full"
              />

              <legend class="fieldset-legend">Result Column Name</legend>
              <input
                type="text"
                name="tournament[result_column_name]"
                value={@tournament.result_column_name}
                class="input input-bordered w-full"
              />
            </fieldset>

            <div class="mt-4">
              <button type="submit" class="btn btn-primary">Save Tournament</button>
            </div>
          </.form>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Teams</h2>
            <button type="button" phx-click="calculate_ideal" class="btn btn-secondary btn-sm">
              Calculate Ideal Pick
            </button>
          </div>

          <.form for={%{}} phx-submit="save_all_teams" class="space-y-4">
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Price</th>
                    <th>Points</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <%= for team <- @teams do %>
                    <tr>
                      <td>
                        <input
                          type="text"
                          name={"teams[#{team.id}][name]"}
                          value={team.name}
                          class="input input-bordered input-sm w-full"
                          required
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          name={"teams[#{team.id}][price]"}
                          value={team.price}
                          class="input input-bordered input-sm w-20"
                          min="1"
                          required
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          name={"teams[#{team.id}][points]"}
                          value={team.points}
                          class="input input-bordered input-sm w-20"
                          min="0"
                        />
                      </td>
                      <td>
                        <button
                          type="button"
                          phx-click="delete_team"
                          phx-value-id={team.id}
                          class="btn btn-ghost btn-xs text-error"
                        >
                          ✕
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="flex gap-2">
              <button type="button" phx-click="add_team" class="btn btn-outline btn-sm">
                + Add Team
              </button>
              <button type="submit" class="btn btn-primary btn-sm">Save All Teams</button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp format_datetime_local(datetime) when is_struct(datetime, DateTime) do
    Calendar.strftime(datetime, "%Y-%m-%dT%H:%M")
  end

  defp format_datetime_local(_), do: ""
end

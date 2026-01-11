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
       changeset: changeset,
       editing_team_id: nil
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
    # Convert deadline string to milliseconds
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
  def handle_event("edit_team", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_team_id: String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit_team", _, socket) do
    {:noreply, assign(socket, editing_team_id: nil)}
  end

  @impl true
  def handle_event("save_team", %{"team" => params}, socket) do
    team = Enum.find(socket.assigns.teams, &(&1.id == socket.assigns.editing_team_id))

    case Tournaments.update_team(team, params) do
      {:ok, _} ->
        teams = Tournaments.list_teams_for_tournament(socket.assigns.tournament.id)

        {:noreply,
         socket
         |> assign(teams: teams, editing_team_id: nil)
         |> put_flash(:info, "Team updated.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update team.")}
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

          <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Title</span>
              </label>
              <input
                type="text"
                name="tournament[title]"
                value={@tournament.title}
                class="input input-bordered"
                required
              />
            </div>

            <div class="grid md:grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Max Teams</span>
                </label>
                <input
                  type="number"
                  name="tournament[max_teams]"
                  value={@tournament.max_teams}
                  class="input input-bordered"
                  min="1"
                  max="20"
                  required
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Max Price</span>
                </label>
                <input
                  type="number"
                  name="tournament[max_price]"
                  value={@tournament.max_price}
                  class="input input-bordered"
                  min="1"
                  required
                />
              </div>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Deadline</span>
              </label>
              <input
                type="datetime-local"
                name="tournament[deadline]"
                value={format_datetime_local(@tournament.deadline)}
                class="input input-bordered"
                required
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Spreadsheet URL</span>
              </label>
              <input
                type="url"
                name="tournament[spreadsheet_url]"
                value={@tournament.spreadsheet_url}
                class="input input-bordered"
              />
            </div>

            <div class="grid md:grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Team Column Name</span>
                </label>
                <input
                  type="text"
                  name="tournament[team_column_name]"
                  value={@tournament.team_column_name}
                  class="input input-bordered"
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Result Column Name</span>
                </label>
                <input
                  type="text"
                  name="tournament[result_column_name]"
                  value={@tournament.result_column_name}
                  class="input input-bordered"
                />
              </div>
            </div>

            <div class="form-control mt-4">
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

          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th class="text-right">Price</th>
                  <th class="text-right">Points</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for team <- @teams do %>
                  <%= if @editing_team_id == team.id do %>
                    <tr>
                      <.form for={%{}} phx-submit="save_team" class="contents">
                        <td>
                          <input
                            type="text"
                            name="team[name]"
                            value={team.name}
                            class="input input-bordered input-sm w-full"
                            required
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            name="team[price]"
                            value={team.price}
                            class="input input-bordered input-sm w-20"
                            min="1"
                            required
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            name="team[points]"
                            value={team.points}
                            class="input input-bordered input-sm w-20"
                            min="0"
                          />
                        </td>
                        <td class="flex gap-1">
                          <button type="submit" class="btn btn-success btn-xs">Save</button>
                          <button type="button" phx-click="cancel_edit_team" class="btn btn-ghost btn-xs">
                            Cancel
                          </button>
                        </td>
                      </.form>
                    </tr>
                  <% else %>
                    <tr>
                      <td>{team.name}</td>
                      <td class="text-right">{team.price}</td>
                      <td class="text-right">{team.points}</td>
                      <td>
                        <button
                          type="button"
                          phx-click="edit_team"
                          phx-value-id={team.id}
                          class="btn btn-ghost btn-xs"
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
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

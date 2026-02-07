defmodule FantasyWeb.TournamentLive.Create do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments
  alias Fantasy.Tournaments.Tournament

  on_mount {FantasyWeb.Live.Hooks, :require_auth}
  on_mount {FantasyWeb.Live.Hooks, :require_admin}

  @impl true
  def mount(_params, _session, socket) do
    changeset = Tournament.create_changeset(%Tournament{}, %{})

    {:ok,
     assign(socket,
       page_title: "Create Tournament",
       changeset: changeset,
       teams: [],
       next_team_id: 1
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    tournament_params = Map.get(params, "tournament", %{})

    changeset =
      %Tournament{}
      |> Tournament.create_changeset(tournament_params)
      |> Map.put(:action, :validate)

    teams = update_teams_from_params(socket.assigns.teams, Map.get(params, "teams", %{}))

    {:noreply, assign(socket, changeset: changeset, teams: teams)}
  end

  @impl true
  def handle_event("add_team", _, socket) do
    new_team = %{temp_id: socket.assigns.next_team_id, name: "", price: 10, points: 0}

    {:noreply,
     assign(socket,
       teams: socket.assigns.teams ++ [new_team],
       next_team_id: socket.assigns.next_team_id + 1
     )}
  end

  @impl true
  def handle_event("remove_team", %{"temp-id" => temp_id}, socket) do
    temp_id = String.to_integer(temp_id)
    teams = Enum.reject(socket.assigns.teams, &(&1.temp_id == temp_id))
    {:noreply, assign(socket, teams: teams)}
  end

  @impl true
  def handle_event("create", params, socket) do
    tournament_params = convert_deadline(Map.get(params, "tournament", %{}))
    teams_params = Map.get(params, "teams", %{})

    teams_data =
      teams_params
      |> Enum.map(fn {_id, p} ->
        %{
          name: String.trim(p["name"] || ""),
          price: parse_int(p["price"], 10),
          points: parse_int(p["points"], 0)
        }
      end)
      |> Enum.reject(fn t -> t.name == "" end)

    with {:ok, tournament} <- Tournaments.create_tournament(tournament_params),
         {:ok, _teams} <- create_teams(tournament.id, teams_data) do
      {:noreply,
       socket
       |> put_flash(:info, "Tournament created successfully!")
       |> push_navigate(to: ~p"/tournaments/#{tournament.slug}/edit")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create tournament.")}
    end
  end

  defp convert_deadline(%{"deadline" => deadline_str} = params) when is_binary(deadline_str) do
    case DateTime.from_iso8601(deadline_str <> ":00Z") do
      {:ok, dt, _} -> Map.put(params, "deadline", DateTime.to_unix(dt, :millisecond))
      _ -> params
    end
  end

  defp convert_deadline(params), do: params

  defp create_teams(_tournament_id, []), do: {:ok, []}

  defp create_teams(tournament_id, teams_data) do
    Tournaments.create_teams_for_tournament(tournament_id, teams_data)
  end

  defp update_teams_from_params(teams, teams_params) do
    Enum.map(teams, fn team ->
      case Map.get(teams_params, to_string(team.temp_id)) do
        nil ->
          team

        params ->
          %{
            team
            | name: Map.get(params, "name", team.name),
              price: parse_int(Map.get(params, "price", team.price), team.price),
              points: parse_int(Map.get(params, "points", team.points), team.points)
          }
      end
    end)
  end

  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_int(_, default), do: default

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-3xl font-bold">Create Tournament</h1>

      <.form for={@changeset} phx-change="validate" phx-submit="create" class="space-y-6">
        <div class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title">Tournament Details</h2>

            <fieldset class="fieldset">
              <legend class="fieldset-legend">Title</legend>
              <input
                type="text"
                name="tournament[title]"
                value={@changeset.changes[:title]}
                class="input input-bordered w-full"
                placeholder="Tournament Name"
                required
              />

              <legend class="fieldset-legend">Slug</legend>
              <input
                type="text"
                name="tournament[slug]"
                value={@changeset.changes[:slug]}
                class="input input-bordered w-full"
                placeholder="tournament-slug"
                required
              />
              <span class="fieldset-label">URL-friendly identifier (lowercase, hyphens)</span>

              <legend class="fieldset-legend">Max Teams</legend>
              <input
                type="number"
                name="tournament[max_teams]"
                value={@changeset.changes[:max_teams] || 5}
                class="input input-bordered w-full"
                min="1"
                max="20"
                required
              />

              <legend class="fieldset-legend">Max Price (Budget)</legend>
              <input
                type="number"
                name="tournament[max_price]"
                value={@changeset.changes[:max_price] || 150}
                class="input input-bordered w-full"
                min="1"
                required
              />

              <legend class="fieldset-legend">Deadline</legend>
              <input
                type="datetime-local"
                name="tournament[deadline]"
                value={@changeset.changes[:deadline]}
                class="input input-bordered w-full"
                required
              />

              <legend class="fieldset-legend">Spreadsheet URL (optional)</legend>
              <input
                type="url"
                name="tournament[spreadsheet_url]"
                value={@changeset.changes[:spreadsheet_url]}
                class="input input-bordered w-full"
                placeholder="https://docs.google.com/spreadsheets/..."
              />
            </fieldset>
          </div>
        </div>

        <div class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title">Teams</h2>

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
                          name={"teams[#{team.temp_id}][name]"}
                          value={team.name}
                          class="input input-bordered input-sm w-full"
                          placeholder="Team name"
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          name={"teams[#{team.temp_id}][price]"}
                          value={team.price}
                          class="input input-bordered input-sm w-20"
                          min="1"
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          name={"teams[#{team.temp_id}][points]"}
                          value={team.points}
                          class="input input-bordered input-sm w-20"
                          min="0"
                        />
                      </td>
                      <td>
                        <button
                          type="button"
                          phx-click="remove_team"
                          phx-value-temp-id={team.temp_id}
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

            <button type="button" phx-click="add_team" class="btn btn-outline btn-sm">
              + Add Team
            </button>
          </div>
        </div>

        <div class="mt-4">
          <button type="submit" class="btn btn-primary">Create Tournament</button>
        </div>
      </.form>
    </div>
    """
  end
end

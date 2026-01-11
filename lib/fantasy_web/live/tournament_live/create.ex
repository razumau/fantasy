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
       teams_text: ""
     )}
  end

  @impl true
  def handle_event("validate", %{"tournament" => params}, socket) do
    changeset =
      %Tournament{}
      |> Tournament.create_changeset(params)
      |> Map.put(:action, :validate)

    teams_text = Map.get(params, "teams_text", socket.assigns.teams_text)

    {:noreply, assign(socket, changeset: changeset, teams_text: teams_text)}
  end

  @impl true
  def handle_event("create", %{"tournament" => params}, socket) do
    teams_text = Map.get(params, "teams_text", "")
    params = convert_deadline(params)

    with {:ok, tournament} <- Tournaments.create_tournament(params),
         teams_data <- parse_teams(teams_text),
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

  defp parse_teams(text) do
    text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_team_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_team_line(line) do
    case String.split(line, ~r/[,\t]/, parts: 2) do
      [name, price_str] ->
        case Integer.parse(String.trim(price_str)) do
          {price, _} -> %{name: String.trim(name), price: price, points: 0}
          :error -> nil
        end

      [name] ->
        # Default price if not specified
        %{name: String.trim(name), price: 10, points: 0}
    end
  end

  defp create_teams(_tournament_id, []), do: {:ok, []}
  defp create_teams(tournament_id, teams_data) do
    Tournaments.create_teams_for_tournament(tournament_id, teams_data)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-3xl font-bold">Create Tournament</h1>

      <div class="card bg-base-200">
        <div class="card-body">
          <.form for={@changeset} phx-change="validate" phx-submit="create" class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Title</span>
              </label>
              <input
                type="text"
                name="tournament[title]"
                value={@changeset.changes[:title]}
                class="input input-bordered"
                placeholder="Tournament Name"
                required
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Slug</span>
              </label>
              <input
                type="text"
                name="tournament[slug]"
                value={@changeset.changes[:slug]}
                class="input input-bordered"
                placeholder="tournament-slug"
                required
              />
              <label class="label">
                <span class="label-text-alt">URL-friendly identifier (lowercase, hyphens)</span>
              </label>
            </div>

            <div class="grid md:grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Max Teams</span>
                </label>
                <input
                  type="number"
                  name="tournament[max_teams]"
                  value={@changeset.changes[:max_teams] || 5}
                  class="input input-bordered"
                  min="1"
                  max="20"
                  required
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Max Price (Budget)</span>
                </label>
                <input
                  type="number"
                  name="tournament[max_price]"
                  value={@changeset.changes[:max_price] || 150}
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
                value={@changeset.changes[:deadline]}
                class="input input-bordered"
                required
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Spreadsheet URL (optional)</span>
              </label>
              <input
                type="url"
                name="tournament[spreadsheet_url]"
                value={@changeset.changes[:spreadsheet_url]}
                class="input input-bordered"
                placeholder="https://docs.google.com/spreadsheets/..."
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Teams</span>
              </label>
              <textarea
                name="tournament[teams_text]"
                class="textarea textarea-bordered h-48 font-mono"
                placeholder="Team Name, Price&#10;Team One, 25&#10;Team Two, 30&#10;Team Three, 15"
              >{@teams_text}</textarea>
              <label class="label">
                <span class="label-text-alt">One team per line: "Name, Price" or just "Name" for default price</span>
              </label>
            </div>

            <div class="form-control mt-6">
              <button type="submit" class="btn btn-primary">Create Tournament</button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end

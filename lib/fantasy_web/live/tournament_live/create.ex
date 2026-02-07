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
  def handle_event("validate", params, socket) do
    tournament_params = Map.get(params, "tournament", %{})

    changeset =
      %Tournament{}
      |> Tournament.create_changeset(tournament_params)
      |> Map.put(:action, :validate)

    teams_text = Map.get(params, "teams_text", socket.assigns.teams_text)

    {:noreply, assign(socket, changeset: changeset, teams_text: teams_text)}
  end

  @impl true
  def handle_event("create", params, socket) do
    tournament_params = convert_deadline(Map.get(params, "tournament", %{}))
    teams_text = Map.get(params, "teams_text", "")

    teams_data = parse_teams(teams_text)

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

  defp parse_teams(text) do
    text
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_team_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_team_line(line) do
    case Regex.run(~r/^(.+)\s+(\d+)$/, line) do
      [_, name, price_str] ->
        {price, _} = Integer.parse(price_str)
        %{name: String.trim(name), price: price, points: 0}

      nil ->
        %{name: String.trim(line), price: 10, points: 0}
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

            <fieldset class="fieldset">
              <legend class="fieldset-legend">Teams (one per line)</legend>
              <textarea
                name="teams_text"
                class="textarea textarea-bordered h-48 w-full font-mono"
                placeholder={"Team Name 25\nAnother Team 30\nThird Team 15"}
              >{@teams_text}</textarea>
              <span class="fieldset-label">
                One team per line: "Team Name 50" (name and price separated by the last space)
              </span>
            </fieldset>
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

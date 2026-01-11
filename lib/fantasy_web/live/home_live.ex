defmodule FantasyWeb.HomeLive do
  use FantasyWeb, :live_view

  alias Fantasy.Tournaments

  on_mount {FantasyWeb.Live.Hooks, :maybe_auth}

  @impl true
  def mount(_params, _session, socket) do
    open_tournaments = Tournaments.list_open_tournaments()
    closed_tournaments = Tournaments.list_closed_tournaments()

    {:ok,
     assign(socket,
       page_title: "Tournaments",
       open_tournaments: open_tournaments,
       closed_tournaments: closed_tournaments
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <section>
        <h2 class="text-2xl font-bold mb-4">Open Tournaments</h2>
        <%= if Enum.empty?(@open_tournaments) do %>
          <p class="text-base-content/60">No open tournaments at the moment.</p>
        <% else %>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <%= for tournament <- @open_tournaments do %>
              <.tournament_card tournament={tournament} open={true} />
            <% end %>
          </div>
        <% end %>
      </section>

      <section>
        <h2 class="text-2xl font-bold mb-4">Past Tournaments</h2>
        <%= if Enum.empty?(@closed_tournaments) do %>
          <p class="text-base-content/60">No past tournaments.</p>
        <% else %>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <%= for tournament <- @closed_tournaments do %>
              <.tournament_card tournament={tournament} open={false} />
            <% end %>
          </div>
        <% end %>
      </section>
    </div>
    """
  end

  defp tournament_card(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-sm">
      <div class="card-body">
        <h3 class="card-title">{@tournament.title}</h3>
        <p class="text-sm text-base-content/60">
          <%= if @open do %>
            Deadline: {format_deadline(@tournament.deadline)}
          <% else %>
            Ended: {format_deadline(@tournament.deadline)}
          <% end %>
        </p>
        <p class="text-sm">
          Max teams: {@tournament.max_teams} | Budget: {@tournament.max_price}
        </p>
        <div class="card-actions justify-end mt-2">
          <%= if @open do %>
            <.link navigate={~p"/tournaments/#{@tournament.slug}"} class="btn btn-primary btn-sm">
              Pick Teams
            </.link>
          <% else %>
            <.link navigate={~p"/tournaments/#{@tournament.slug}/results"} class="btn btn-ghost btn-sm">
              Results
            </.link>
            <.link navigate={~p"/tournaments/#{@tournament.slug}/popular"} class="btn btn-ghost btn-sm">
              Popular
            </.link>
          <% end %>
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

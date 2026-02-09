defmodule FantasyWeb.Live.Hooks do
  @moduledoc """
  LiveView hooks for authentication.

  These can be used with `on_mount` in LiveViews to handle authentication.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias Fantasy.Accounts

  @doc """
  on_mount callback for LiveView authentication.

  ## Hooks

  - `:require_auth` - Redirects to login if no user in session
  - `:require_admin` - Requires admin privileges (use after :require_auth)
  - `:maybe_auth` - Optionally loads user, no redirect if not logged in
  """
  def on_mount(hook, params, session, socket)

  def on_mount(:require_auth, _params, session, socket) do
    case session["user_id"] do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must be logged in to access this page.")
          |> redirect(to: "/auth/login")

        {:halt, socket}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            socket =
              socket
              |> put_flash(:error, "Session expired. Please log in again.")
              |> redirect(to: "/auth/login")

            {:halt, socket}

          user ->
            {:cont, assign(socket, :current_user, user)}
        end
    end
  end

  def on_mount(:require_admin, _params, _session, socket) do
    user = socket.assigns[:current_user]

    if Accounts.admin?(user) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You don't have permission to access this page.")
        |> redirect(to: "/")

      {:halt, socket}
    end
  end

  def on_mount(:maybe_auth, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont, assign(socket, :current_user, user)}
  end
end

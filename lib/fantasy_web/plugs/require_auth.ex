defmodule FantasyWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug that requires authentication.

  Redirects to login page if no user is in the session.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Fantasy.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/auth/login?return_to=#{conn.request_path}")
        |> halt()

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            conn
            |> configure_session(drop: true)
            |> put_flash(:error, "Session expired. Please log in again.")
            |> redirect(to: "/auth/login?return_to=#{conn.request_path}")
            |> halt()

          user ->
            assign(conn, :current_user, user)
        end
    end
  end
end

defmodule FantasyWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug that requires admin privileges.

  Must be used after RequireAuth to ensure current_user is set.
  Redirects to home page if user is not an admin.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Fantasy.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if Accounts.admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end

defmodule FantasyWeb.Plugs.FetchCurrentUser do
  @moduledoc """
  Plug that fetches the current user from the session.

  This plug should be used in all browser pipelines to make
  the current user available in assigns.
  """
  import Plug.Conn

  alias Fantasy.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      case Accounts.get_user(user_id) do
        nil -> assign(conn, :current_user, nil)
        user -> assign(conn, :current_user, user)
      end
    else
      assign(conn, :current_user, nil)
    end
  end
end

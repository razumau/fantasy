defmodule FantasyWeb.AuthController do
  use FantasyWeb, :controller

  alias Fantasy.Accounts

  @doc """
  Initiates the Google OAuth flow by redirecting to Google's authorization page.
  """
  def login(conn, params) do
    # Store the return path if provided
    return_to = params["return_to"] || "/"

    oauth_google_url = ElixirAuthGoogle.generate_oauth_url(conn)

    conn
    |> put_session(:return_to, return_to)
    |> redirect(external: oauth_google_url)
  end

  @doc """
  Handles the OAuth callback from Google.

  Fetches user profile data and finds or creates the user in our database.
  """
  def callback(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)

    case Accounts.find_or_create_user(profile) do
      {:ok, user} ->
        return_to = get_session(conn, :return_to) || "/"

        conn
        |> put_session(:user_id, user.id)
        |> delete_session(:return_to)
        |> redirect(to: return_to)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to authenticate. Please try again.")
        |> redirect(to: "/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: "/")
  end

  @doc """
  Logs out the user by clearing the session.
  """
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end

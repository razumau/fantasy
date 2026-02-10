defmodule FantasyWeb.Router do
  use FantasyWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FantasyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FantasyWeb.Plugs.FetchCurrentUser
  end

  pipeline :require_auth do
    plug FantasyWeb.Plugs.RequireAuth
  end

  pipeline :require_admin do
    plug FantasyWeb.Plugs.RequireAuth
    plug FantasyWeb.Plugs.RequireAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", FantasyWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/tournaments/:slug/results", TournamentLive.Results
    live "/tournaments/:slug/popular", TournamentLive.Popular
    live "/tournaments/:slug/stats", TournamentLive.Stats
    live "/tournaments/:slug", TournamentLive.Show
  end

  # Auth routes
  scope "/auth", FantasyWeb do
    pipe_through :browser

    get "/login", AuthController, :login
    get "/google/callback", AuthController, :callback
    delete "/logout", AuthController, :logout
  end

  # Admin routes
  scope "/", FantasyWeb do
    pipe_through [:browser, :require_admin]

    live "/tournaments/create", TournamentLive.Create
    live "/tournaments/:slug/edit", TournamentLive.Edit
  end

  scope "/admin" do
    pipe_through [:browser, :require_admin]
    live_dashboard "/dashboard", metrics: FantasyWeb.Telemetry
  end
end

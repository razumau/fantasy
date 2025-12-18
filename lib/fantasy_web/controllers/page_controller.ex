defmodule FantasyWeb.PageController do
  use FantasyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

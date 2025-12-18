defmodule FantasyWeb.ErrorJSONTest do
  use FantasyWeb.ConnCase, async: true

  test "renders 404" do
    assert FantasyWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert FantasyWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

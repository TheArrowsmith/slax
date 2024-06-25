defmodule SlaxWeb.ErrorJSONTest do
  use SlaxWeb.ConnCase, async: true

  test "renders 404" do
    assert SlaxWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert SlaxWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

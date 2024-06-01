defmodule Open890Web.PageControllerTest do
  use Open890Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")

    assert conn |> redirected_to() == "/connections"
  end
end

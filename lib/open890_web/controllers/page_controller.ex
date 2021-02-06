defmodule Open890Web.PageController do
  use Open890Web, :controller

  def index(conn, _params) do
    conn |> render("index.html")
  end
end

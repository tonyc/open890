defmodule Open890Web.PageController do
  use Open890Web, :controller

  def index(conn, _params) do
    conn
    |> redirect(to: "/connections")
    |> halt()
  end
end

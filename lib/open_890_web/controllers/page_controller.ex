defmodule Open890Web.PageController do
  use Open890Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

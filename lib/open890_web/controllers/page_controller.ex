defmodule Open890Web.PageController do
  use Open890Web, :controller

  def index(conn, _params) do
    Phoenix.LiveView.Controller.live_render(conn, Open890Web.RadioLive)
    render(conn, "index.html")
  end
end

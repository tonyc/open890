defmodule Open890Web.RadioConnectionController do
  use Open890Web, :controller

  alias Open890.RadioConnection

  def index(conn, _params) do
    radio_connections = RadioConnection.all()

    conn
    |> assign(:radio_connections, radio_connections)
    |> render("index.html")
  end

end

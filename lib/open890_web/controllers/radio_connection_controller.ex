defmodule Open890Web.RadioConnectionController do
  use Open890Web, :controller

  alias Open890.RadioConnection

  def index(conn, _params) do
    radio_connections = RadioConnection.all()

    conn
    |> assign(:radio_connections, radio_connections)
    |> render("index.html")
  end

  def start(conn, %{"id" => id} = _params) do
    result = id |> RadioConnection.start()


    conn = result
    |> case do
      {:ok, _radio_connection} ->
        Logger.debug("Successfully started connection: #{id}")
        conn
        |> redirect(to: Routes.radio_connection_path(conn, :index))
      {:error, reason} ->
        Logger.debug("Could not start connection #{id}: #{inspect(reason)}")
        conn |> put_status(422)
    end

    conn
  end

  def stop(conn, %{"id" => id} = _params) do
    result = id |> RadioConnection.stop()

    result
    |> case do
      :ok ->
        Logger.info("stopped connection id #{id}")
      {:error, reason} ->
        Logger.warn("Unable to stop connection #{id}: #{inspect(reason)}")
    end

    conn
    |> redirect(to: Routes.radio_connection_path(conn, :index))
  end
end

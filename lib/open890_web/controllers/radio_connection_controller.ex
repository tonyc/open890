defmodule Open890Web.RadioConnectionController do
  use Open890Web, :controller

  alias Open890.RadioConnection

  def index(conn, _params) do
    radio_connections = RadioConnection.all()

    conn
    |> assign(:radio_connections, radio_connections)
    |> render("index.html")
  end

  def new(conn, _params) do
    radio_connection = %RadioConnection{}

    conn
    |> assign(:radio_connection, radio_connection)
    |> render("new.html")
  end

  def create(conn, %{"radio_connection" => radio_connection_params}) do
    radio_connection_params
    |> RadioConnection.create()
    |> case do
      {:ok, %RadioConnection{auto_start: true} = connection} ->
        connection |> RadioConnection.start()

      other ->
        Logger.info("Connection create result: #{inspect(other)}")
    end

    conn |> redirect(to: Routes.radio_connection_path(conn, :index))
  end

  def edit(conn, %{"id" => id} = _params) do
    RadioConnection.find(id)
    |> case do
      {:ok, radio_connection} ->
        conn
        |> assign(:radio_connection, radio_connection)
        |> render("edit.html")

      _ ->
        conn
        |> redirect(to: Routes.radio_connection_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "radio_connection" => radio_params}) do
    id
    |> RadioConnection.find()
    |> case do
      {:ok, radio_connection} ->
        radio_connection
        |> RadioConnection.update_connection(radio_params)
        |> case do
          :ok ->
            conn |> redirect(to: Routes.radio_connection_path(conn, :index))

          {:error, reason} ->
            Logger.debug("Could not update connection: #{inspect(reason)}")
            conn |> render("edit.html")
        end

      _ ->
        Logger.warn("Could not find connection: #{id}")
        conn |> redirect(to: Routes.radio_connection_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    id
    |> RadioConnection.find()
    |> case do
      {:ok, connection} ->
        connection |> RadioConnection.delete_connection()

      _ ->
        Logger.warn("Could not find connection id: #{inspect(id)}")
    end

    conn
    |> redirect(to: Routes.radio_connection_path(conn, :index))
  end

  def start(conn, %{"id" => id} = _params) do
    result = id |> RadioConnection.start()

    conn =
      result
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

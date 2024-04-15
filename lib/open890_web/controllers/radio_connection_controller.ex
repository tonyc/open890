defmodule Open890Web.RadioConnectionController do
  use Open890Web, :controller

  alias Open890.RadioConnection
  alias Open890.ConnectionCommands

  plug :assign_bg_theme

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
        Logger.info("Connection is auto_start, starting")
        connection |> RadioConnection.start()

      other ->
        Logger.info("Connection is not auto-start, create result: #{inspect(other)}")
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

  def wake(conn, %{"id" => id} = _params) do
    case RadioConnection.find(id) do
      {:ok, conn} ->
        ConnectionCommands.wake(conn)

      _ ->
        Logger.warn("Could not find connection: #{inspect(id)}")
    end

    conn
    |> redirect(to: Routes.radio_connection_path(conn, :index))
  end

  def power_off(conn, %{"id" => id} = _params) do
    case RadioConnection.find(id) do
      {:ok, conn} ->
        conn |> ConnectionCommands.power_off()

      _ ->
        Logger.warn("Could not find connection: #{inspect(id)}")
    end

    conn
    |> redirect(to: Routes.radio_connection_path(conn, :index))
  end

  def power_on(conn, %{"id" => id} = _params) do
    case RadioConnection.find(id) do
      {:ok, conn} ->
        conn |> ConnectionCommands.power_on()

      _ ->
        Logger.warn("Could not find connection: #{inspect(id)}")
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

          pretty_error =
            case reason do
              {:bad_return_value, result} ->
                case result do
                  {:error, :ehostunreach} ->
                    "Host unreachable"

                  {:error, :econnrefused} ->
                    "Connection refused"

                  {:error, err} ->
                    "Other error: #{inspect(err)}"

                  err ->
                    "Unknown error: #{inspect(err)}"
                end

              other ->
                Logger.warn("Unmatched error starting connection: #{inspect(other)}")
                inspect(other)
            end

          conn
          |> put_flash(:error, "Error starting connection to radio: #{pretty_error}")
          |> redirect(to: Routes.radio_connection_path(conn, :index))
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

  defp assign_bg_theme(conn, _options) do
    conn |> assign(:bg_theme, "light")
  end
end

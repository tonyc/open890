defmodule Open890.RadioConnection do
  @moduledoc """
  Radio Connection Context Module
  """

  @derive {Inspect, except: [:password]}
  @default_tcp_port "60000"

  defstruct id: nil,
            name: nil,
            ip_address: nil,
            tcp_port: @default_tcp_port,
            mac_address: nil,
            user_name: nil,
            password: nil,
            user_is_admin: false,
            auto_start: true,
            type: nil,
            cloudlog_enabled: false,
            cloudlog_url: nil,
            cloudlog_api_key: nil,
            user_markers: []

  require Logger

  alias Open890.{CloudlogSupervisor, RadioConnectionSupervisor}
  alias Open890.RadioConnectionRepo, as: Repo
  alias Open890.{ConnectionCommands, RadioState, UserMarker}

  def mac_address(connection) do
    connection |> Map.get(:mac_address, nil)
  end

  def tcp_port(%__MODULE__{} = connection) do
    connection
    |> Map.get(:tcp_port, @default_tcp_port)
    |> case do
      "" -> @default_tcp_port
      str when is_binary(str) -> String.to_integer(str)
    end
  end

  def find(id) do
    id |> repo().find()
  end

  def all do
    repo().all()
  end

  def first, do: all() |> Enum.at(0)

  def add_user_marker(%__MODULE__{id: _id} = _connection, %UserMarker{} = _marker) do
    # the problem here is that the old connection struct seemingly doesn't even
    # have a :user_markers key, despite it being in the struct. it's like it's completely
    # frozen in the previous state when coming from dets, keys and all

    # connection = put_in(connection, :user_markers, user_markers(connection) ++ [marker])
    # repo().update(connection)
    :ok
  end

  def delete_user_marker(%__MODULE__{} = _connection, _user_marker_id) do
    :ok
  end

  def clear_user_markers(%__MODULE__{} = _connection) do
    # repo().update(%{connection | user_markers: []})
    :ok
  end

  def create(params) when is_map(params) do
    params |> repo().insert()
  end

  def delete_connection(%__MODULE__{id: id}) when is_integer(id) do
    id |> String.to_integer() |> delete_connection()
  end

  def delete_connection(id) do
    id |> repo().delete()
  end

  def delete_all do
    repo().delete_all()
  end

  def get_state!(%__MODULE__{} = conn) do
    get_state(conn)
    |> case do
      {:ok, state} -> state
      _ -> raise "State not available for conn: #{conn.id}"
    end
  end

  def get_state(%__MODULE__{} = connection) do
    connection
    |> get_connection_pid()
    |> case do
      {:ok, pid} ->
        pid |> GenServer.call(:get_radio_state)

      _ ->
        Logger.warn("Could not find pid for connection: #{connection.id}")
        {:error, :not_found}
    end
  end

  def update_connection(%__MODULE__{} = conn, params) when is_map(params) do
    # TODO: this should use a changeset
    new_connection =
      conn
      |> Map.merge(%{
        name: params["name"],
        ip_address: params["ip_address"],
        tcp_port: params["tcp_port"],
        mac_address: params["mac_address"],
        user_name: params["user_name"],
        password: params["password"],
        user_is_admin: params["user_is_admin"],
        auto_start: params["auto_start"],
        cloudlog_enabled: params["cloudlog_enabled"],
        cloudlog_url:
          params["cloudlog_url"] |> to_string() |> String.trim() |> String.trim_trailing("/"),
        cloudlog_api_key: params["cloudlog_api_key"] |> to_string() |> String.trim()
      })

    new_connection |> repo().update()
  end

  def count_connections do
    repo().count()
  end

  def start(id) when is_integer(id) or is_binary(id) do
    with {:ok, conn} <- find(id) do
      conn |> start()
    end
  end

  def start(%__MODULE__{} = connection) do
    broadcast_connection_state(connection, :starting)
    maybe_start_cloudlog_process(connection)
    start_tcp_process(connection)
  end

  defp start_tcp_process(%__MODULE__{} = connection) do
    connection
    |> RadioConnectionSupervisor.start_connection()
    |> case do
      {:ok, _pid} ->
        {:ok, connection}

      {:error, {:already_started, _pid}} ->
        {:error, :already_started}

      other ->
        other
    end
  end

  defp maybe_start_cloudlog_process(%__MODULE__{} = connection) do
    connection
    |> Map.get(:cloudlog_enabled, false)
    |> case do
      truthy when truthy in [true, "true"] ->
        Logger.info("Cloudlog enabled for connection #{connection.id}, starting process")

        connection
        |> CloudlogSupervisor.start_cloudlog()
        |> case do
          {:ok, _pid} ->
            {:ok, connection}

          {:error, {:already_started, _pid}} ->
            {:error, :already_started}

          other ->
            other
        end

      _ ->
        Logger.info("Cloudlog not enabled for connection #{connection.id}")
        {:ok, connection}
    end
  end

  def stop(id) when is_integer(id) or is_binary(id) do
    with {:ok, conn} <- find(id) do
      conn |> stop()
    end
  end

  def stop(%__MODULE__{} = connection) do
    # This should be a proper process tree where we just terminate one
    # process for the connection, which would actually be a supervisor with
    # a TCP process and possibly a cloudlog process.
    maybe_terminate_cloudlog_process(connection)
    terminate_tcp_process(connection)
  end

  defp terminate_tcp_process(%__MODULE__{id: connection_id} = connection) do
    Registry.lookup(:radio_connection_registry, {:tcp, connection_id})
    |> case do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(RadioConnectionSupervisor, pid)
        broadcast_connection_state(connection, :stopped)
        :ok

      _ ->
        Logger.debug("Unable to find TCP process for connection id #{connection_id}")
        {:error, :not_found}
    end
  end

  defp maybe_terminate_cloudlog_process(%__MODULE__{id: connection_id}) do
    Registry.lookup(:radio_connection_registry, {:cloudlog, connection_id})
    |> case do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(CloudlogSupervisor, pid)

      _ ->
        Logger.debug("Unable to find cloudlog process for connection id #{connection_id}")
        {:error, :not_found}
    end
  end

  def update_cloudlog(%__MODULE__{} = connection, %RadioState{} = radio_state) do
    connection
    |> get_cloudlog_pid()
    |> case do
      {:ok, pid} ->
        pid |> GenServer.cast({:update, connection.id, radio_state})

      _ ->
        Logger.warn("update_cloudlog: no PID found for connection:#{connection.id}")
    end

    connection
  end

  def send_mic_audio(%__MODULE__{} = connection, data) do
    Logger.info("RadioConnection.send_mic_audio")
    connection
    |> get_connection_pid()
    |> case do
      {:ok, pid} ->
        pid |> GenServer.cast({:send_audio, data})

      _ ->
        Logger.warn("Unable to send mic audio to #{connection.id} - pid not found. Is the connection up?")
    end
  end

  def query_power_state(connection) do
    connection |> cmd("PS")
  end

  def cmd(%__MODULE__{} = connection, command) when is_binary(command) do
    connection
    |> get_connection_pid()
    |> case do
      {:ok, pid} ->
        pid |> cast_cmd(command)

      {:error, _reason} ->
        Logger.warn(
          "Unable to send command to connection #{inspect(connection)}, pid not found. Is the connection up?"
        )
    end

    connection
  end

  defp cast_cmd(pid, command) when is_pid(pid) and is_binary(command) do
    pid |> GenServer.cast({:send_command, command})
  end

  def process_exists?(%__MODULE__{} = conn) do
    conn
    |> get_connection_pid()
    |> case do
      {:ok, _} -> true
      _ -> false
    end
  end

  def power_off(%{id: _id} = conn) do
    ConnectionCommands.power_off(conn)
  end

  def broadcast_freq_delta(%__MODULE__{id: id} = _connection, args) do
    Open890Web.Endpoint.broadcast("connection:#{id}", "freq_delta", args)
  end

  def broadcast_connection_state(%__MODULE__{id: id} = _connection, state) do
    Open890Web.Endpoint.broadcast("connection:#{id}", "connection_state", %{id: id, state: state})
  end

  def broadcast_power_state(%__MODULE__{id: id} = _connection, power_state) do
    Open890Web.Endpoint.broadcast("connection:#{id}", "power_state", %{id: id, state: power_state})
  end

  def broadcast_band_scope(%__MODULE__{id: id}, band_scope_data) do
    Open890Web.Endpoint.broadcast("radio:band_scope:#{id}", "band_scope_data", %{
      payload: band_scope_data
    })
  end

  def broadcast_audio_scope(%__MODULE__{id: id}, audio_scope_data) do
    Open890Web.Endpoint.broadcast("radio:audio_scope:#{id}", "scope_data", %{
      payload: audio_scope_data
    })
  end

  def broadcast_radio_state(%__MODULE__{id: id}, %RadioState{} = radio_state) do
    Open890Web.Endpoint.broadcast("radio:state:#{id}", "radio_state_data", %{
      msg: radio_state
    })
  end

  def broadcast_band_scope_cleared(%__MODULE__{id: id}) do
    Open890Web.Endpoint.broadcast("radio:band_scope:#{id}", "band_scope_cleared", %{})
  end

  def broadcast_lock_state(%__MODULE__{id: id} = _connection, args) do
    Open890Web.Endpoint.broadcast("radio:band_scope:#{id}", "lock_state", args)
  end

  # bundles up all the knowledge of which topics to subscribe a topic to
  def subscribe(target, connection_id) do
    Phoenix.PubSub.subscribe(target, "radio:state:#{connection_id}")
    Phoenix.PubSub.subscribe(target, "radio:audio_scope:#{connection_id}")
    Phoenix.PubSub.subscribe(target, "radio:band_scope:#{connection_id}")
    Phoenix.PubSub.subscribe(target, "connection:#{connection_id}")
  end

  defp get_connection_pid(%__MODULE__{id: id}) do
    Registry.lookup(:radio_connection_registry, {:tcp, id})
    |> case do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def get_cloudlog_pid(%__MODULE__{id: id}) do
    Registry.lookup(:radio_connection_registry, {:cloudlog, id})
    |> case do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def repo, do: Repo
end

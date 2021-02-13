defmodule Open890.RadioConnection do
  @moduledoc """
  Radio Connection Context Module
  """

  @derive {Inspect, only: [:id, :name, :type, :ip_address, :user_name]}

  defstruct id: nil, name: nil, ip_address: nil, user_name: nil, password: nil, user_is_admin: false, type: nil

  require Logger

  alias Open890.RadioConnectionSupervisor
  alias Open890.RadioConnectionRepo, as: Repo

  def find(id) do
    id |> Repo.find()
  end

  def all do
    Repo.all()
  end

  def create(params) when is_map(params) do
    params |> Repo.insert()
  end

  def start(id) when is_integer(id) or is_binary(id) do
    with {:ok, conn} <- find(id) do
      conn |> start()
    end
  end

  def start(%__MODULE__{} = connection) do
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

  def stop(id) when is_integer(id) or is_binary(id) do
    with {:ok, conn} <- find(id) do
      conn |> stop()
    end
  end

  def stop(%__MODULE__{id: id}) do
    Registry.lookup(:radio_connection_registry, id)
    |> case do
      [{pid, _}] ->
        RadioConnectionSupervisor
        |> DynamicSupervisor.terminate_child(pid)
      _ ->
        Logger.debug("Unable to find process for connection id #{id}")
        {:error, :not_found}
    end

  end

  def cmd(%__MODULE__{} = connection, command) when is_binary(command) do
    connection
    |> get_connection_pid()
    |> case do
      {:ok, pid} -> pid |> cast_cmd(command)
      {:error, _reason} ->
        Logger.warn("Unable to send command to connection #{inspect(connection)}, pid not found. Is the connection up?")
    end
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

  defp get_connection_pid(%__MODULE__{id: id}) do
    Registry.lookup(:radio_connection_registry, id)
    |> case do
      [{pid, _}]  -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end


end

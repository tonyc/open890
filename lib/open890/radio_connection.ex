defmodule Open890.RadioConnection do
  @derive {Inspect, only: [:id, :type, :ip_address, :user_name]}

  defstruct id: nil, ip_address: nil, user_name: nil, password: nil, user_is_admin: false, type: nil

  require Logger

  alias Open890.RadioConnectionSupervisor

  def find(1 = id) do
    {:ok,
      %__MODULE__{
        type: :tcp,
        id: id,
        ip_address: "192.168.1.229",
        user_name: "testuser",
        password: "testpass123!",
        user_is_admin: false
      }
    }
  end

  def find(id) when is_binary(id) do
    id |> String.to_integer() |> find()
  end

  def find(_) do
    {:error, :not_found}
  end

  def start(id) when is_integer(id) do
    with {:ok, conn} <- find(id) do
      conn |> start()
    end
  end

  def start(%__MODULE__{} = connection) do
    {:ok, _pid} = RadioConnectionSupervisor.start_connection(connection)
    connection
  end

  def stop(id) when is_integer(id) do
    with {:ok, conn} <- find(id) do
      conn |> stop()
    end
  end

  def stop(%__MODULE__{id: id}) do
    [{pid, _}] = Registry.lookup(:radio_connection_registry, id)

    RadioConnectionSupervisor
    |> DynamicSupervisor.terminate_child(pid)
  end

  def cmd(%__MODULE__{} = connection, command) when is_binary(command) do
    Logger.debug("cmd(#{inspect(command)}): Finding pid for #{inspect(connection)}")

    connection
    |> get_connection_pid()
    |> cast_cmd(command)
  end

  defp cast_cmd(pid, command) when is_pid(pid) and is_binary(command) do
    pid |> GenServer.cast({:send_command, command})
  end

  defp get_connection_pid(%__MODULE__{id: id}) do
    [{pid, _}] = Registry.lookup(:radio_connection_registry, id)
    pid
  end



end

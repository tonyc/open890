defmodule Open890.RadioConnection do
  defstruct id: nil, ip_address: nil, user_name: nil, password: nil, user_is_admin: false, pid: nil

  alias Open890.RadioConnectionSupervisor

  def find(1 = id) do
    {:ok,
      %__MODULE__{
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
    {:ok, pid} = RadioConnectionSupervisor.start_connection(connection)

    %{connection | pid: pid}
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

  def get_connection_pid(%__MODULE__{id: id}) do
    [{pid, _}] = Registry.lookup(:radio_connection_registry, id)
    pid
  end



end

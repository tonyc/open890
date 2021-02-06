defmodule Open890.RadioConnectionRepo do
  @table_name :"db/radio_connections.dets"
  @select_all [{:"$1", [], [:"$1"]}]

  require Logger

  alias Open890.RadioConnection

  def all do
    @table_name
    |> :dets.select(@select_all)
    |> Enum.map(fn {_id, conn} -> conn end)
  end

  def find("1"), do: find(1)

  def find(1) do
    {:ok,
      %RadioConnection{
        type: :tcp,
        id: 1,
        name: "TS-890 Default",
        ip_address: "192.168.1.229",
        user_name: "testuser",
        password: "testpass123!",
        user_is_admin: false
      }
    }
  end

  def find(id) do
    @table_name
    |> :dets.lookup(id)
    |> case do
      [{
        ^id,
        %RadioConnection{} = conn
      }] -> {:ok, conn}
      _ -> {:error, :not_found}
    end
  end


  def all_raw do
    @table_name
    |> :dets.select(@select_all)
  end

  def init do
    Logger.debug("RadioConnectionRepo.init")
    :dets.open_file(@table_name, [type: :set])
  end

  def insert(%RadioConnection{id: nil} = conn) do
    id = UUID.uuid4()
    conn = %{conn | id: id}

    @table_name
    |> :dets.insert_new({id, conn})
  end

  def delete(%RadioConnection{id: id} = _conn) do
    @table_name
    |> :dets.delete(id)
  end
end

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

  def insert(%{"radio_connection" => %{
    "name" => name,
    "ip_address" => ip_address,
    "user_name" => user_name,
    "password" => password,
    "user_is_admin" => user_is_admin
  }} = _params) do
    %RadioConnection{
      id: nil,
      type: :tcp,
      name: name,
      ip_address: ip_address,
      user_name: user_name,
      password: password,
      user_is_admin: user_is_admin
    }
    |> insert()

  end

  def insert(%RadioConnection{id: nil} = conn) do
    id = UUID.uuid4()
    conn = %{conn | id: id}

    @table_name |> :dets.insert_new({id, conn})
  end

  def update(%RadioConnection{id: id} = conn) when not is_nil(id) do
    @table_name |> :dets.insert({id, conn})
  end

  def delete(%RadioConnection{id: id} = _conn) do
    id |> __delete()
  end

  def __delete(id) do
    @table_name |> :dets.delete(id)
  end
end

defmodule Open890.CloudlogSupervisor do
  use DynamicSupervisor
  require Logger

  alias Open890.RadioConnection

  def start_link(init_arg) do
    Logger.info("*** Cloudlog Supervisor started")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_cloudlog(%RadioConnection{id: id}) do
    spec = {Open890.Cloudlog, %{connection_id: id}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule Open890.RadioConnectionSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_connection(args) do
    spec = {Open890.TCPClient, args}
    res = DynamicSupervisor.start_child(__MODULE__, spec)
    IO.puts "Result from starting child: #{inspect(res)}"

    res
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end


end

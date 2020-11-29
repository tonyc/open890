defmodule Open890Web.Live.BandscopeComponent do
  use Open890Web, :live_component

  require Logger

  @impl true
  def mount(socket) do
    IO.puts "~~~~~~~~~~~ BANDSCOPE COMPONENT"
    socket |> IO.inspect(label: "bandscope socket", limit: :infinity)
    IO.puts "~~~~~~~~~~~ END BANDSCOPE COMPONENT"
    {:ok, socket}
  end

end

defmodule Open890Web.Live.ButtonsComponent do
  use Open890Web, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end

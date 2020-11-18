defmodule Open890Web.Live.BandscopeComponent do
  use Open890Web, :live_component

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end

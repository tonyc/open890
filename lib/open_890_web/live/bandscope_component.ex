defmodule Open890Web.BandscopeComponent do
  use Open890Web, :live_component

  use Phoenix.LiveComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do

    {:ok, socket}
  end

end

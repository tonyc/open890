defmodule Open890Web.RadioLive do
  use Phoenix.LiveView

  require Logger
  alias Open890Web.PageView


  @impl true
  def render(assigns) do
    PageView.render("radio.html", assigns)
  end

  @impl true
  def handle_event("mic_up", _meta, socket) do
    Logger.info("Event: mic_up")

    {:noreply, socket}
  end
end

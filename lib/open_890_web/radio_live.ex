defmodule Open890Web.RadioLive do
  use Phoenix.LiveView

  require Logger
  alias Open890Web.PageView
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("LiveView mount()")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
    end

    {:ok,
      socket
        |> assign(:s_meter, "0")
        |> assign(:vfo_a_frequency, "FA00000000000")
    }
  end

  @impl true
  def render(assigns) do
    PageView.render("radio.html", assigns)
  end

  @impl true
  def handle_event("mic_up", _meta, socket) do
    Logger.info("Event: mic_up")
    Open890.ch_up()

    # This should look something like:
    # Radio.mic_up()

    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_dn", _meta, socket) do
    Logger.info("Event: mic_dn")
    Open890.ch_down()

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    cond do
      msg |> String.starts_with?("SM") ->
        {:noreply, socket |> assign(:s_meter, msg)}

      msg |> String.starts_with?("FA") ->
        {:noreply, socket |> assign(:vfo_a_frequency, msg)}
      true ->
        {:noreply, socket}
    end
  end
end

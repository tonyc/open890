defmodule Open890Web.RadioLive do
  use Open890Web, :live_view

  require Logger

  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("LiveView mount()")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
    end

    Open890.get_vfo_a_freq()
    Open890.get_vfo_b_freq()


    {:ok,
      socket
        |> assign(:s_meter, "0")
        |> assign(:vfo_a_frequency, "FA00000000000")
        |> assign(:vfo_b_frequency, "FB00000000000")
    }
  end

  @impl true
  def handle_event("mic_up", _params, socket) do
    Logger.info("Event: mic_up")
    Open890.ch_up()

    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_dn", _params, socket) do
    Logger.info("Event: mic_dn")
    Open890.ch_down()

    {:noreply, socket}
  end

  @impl true
  def handle_event("multi_ch", %{"is_up" => is_up} = params, socket) do
    Logger.info("Event: multi/ch, meta: #{inspect(params)}")

    direction = if is_up do
      :up
    else
      :down
    end

    Open890.freq_change(direction)

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

      msg |> String.starts_with?("FB") ->
        {:noreply, socket |> assign(:vfo_b_frequency, msg)}



      true ->
        {:noreply, socket}
    end
  end
end

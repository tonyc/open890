defmodule Open890Web.RadioLive do
  use Open890Web, :live_view
  require Logger
  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("LiveView mount()")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:audio_scope")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
    end

    Radio.get_vfo_a_freq()
    Radio.get_vfo_b_freq()

    {:ok,
      socket
        |> assign(:s_meter, "")
        |> assign(:vfo_a_frequency, "")
        |> assign(:vfo_b_frequency, "")
    }
  end

  @impl true
  def handle_event("mic_up", _params, socket) do
    Radio.ch_up()
    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_dn", _params, socket) do
    Radio.ch_down()
    {:noreply, socket}
  end

  @impl true
  def handle_event("multi_ch", %{"is_up" => true} = params, socket) do
    Logger.debug("multi_ch: params: #{inspect(params)}")
    Radio.freq_change(:up)

    {:noreply, socket}
  end


  @impl true
  def handle_event("multi_ch", %{"is_up" => false} = params, socket) do
    Logger.debug("multi_ch: params: #{inspect(params)})")
    Radio.freq_change(:down)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "scope_data", payload: payload}, socket) do
    {:noreply,
      socket |> push_event(:audio_scope_data, payload)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: payload}, socket) do
    {:noreply,
      socket |> push_event(:band_scope_data, payload)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    cond do
      msg |> String.starts_with?("SM") ->
        {:noreply, socket |> assign(:s_meter, msg |> format_s_meter())}

      msg |> String.starts_with?("FA") ->
        {:noreply, socket |> assign(:vfo_a_frequency, msg |> format_vfo_freq())}

      msg |> String.starts_with?("FB") ->
        {:noreply, socket |> assign(:vfo_b_frequency, msg |> format_vfo_freq())}

      true ->
        Logger.debug("RadioLive: unknown message: #{inspect(msg)}")
        {:noreply, socket}
    end
  end

  defp format_vfo_freq(str) when is_binary(str) do
    str
    |> String.trim_leading("FA")
    |> String.trim_leading("FB")
    |> String.trim_leading("0")
    |> String.to_charlist()
    |> Enum.reverse
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(".")
    |> String.reverse
  end

  defp format_s_meter(str) when is_binary(str) do
    str
    |> String.trim_leading("SM")
    |> String.trim_leading("0")
  end
end

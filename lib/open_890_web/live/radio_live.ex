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
    Radio.get_active_receiver()
    Radio.get_band_scope_limits()
    Radio.get_band_scope_mode()

    {:ok,
      socket
        |> assign(:s_meter, "")
        |> assign(:vfo_a_frequency, "")
        |> assign(:vfo_b_frequency, "")
        |> assign(:band_scope_mode, nil)
        |> assign(:band_scope_low, "")
        |> assign(:band_scope_high, "")
        |> assign(:active_receiver, :a)
        |> assign(:active_transmitter, :a)
        |> assign(:band_scope_data, [])
        |> assign(:theme, "elecraft")
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
  def handle_event("cmd", %{"cmd" => cmd} = _params, socket) do
    cmd |> Radio.cmd()
    {:noreply, socket}
  end

  def handle_event("set_theme", %{"theme" => theme_name} = _params, socket) do
    {:noreply,
      socket |> assign(:theme, theme_name)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "scope_data", payload: payload}, socket) do
    {:noreply,
      socket |> push_event(:audio_scope_data, payload)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: %{payload: band_data}}, socket) do
    zipped_data = (0..640)
    |> Enum.zip(band_data)
    |> Enum.map(fn ({index, data}) ->
      "#{index},#{data}"
    end)
    |> Enum.join(" ")

    {:noreply,
      # socket |> push_event(:band_scope_data, payload)
      socket |> assign(:band_scope_data, zipped_data)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    cond do
      msg |> String.starts_with?("BSM0") ->
        low_high = msg |> String.trim_leading("BSM0")

        <<bs_low::binary-size(8), bs_high::binary-size(8)>> = low_high

        {:noreply,
          socket
          |> assign(:band_scope_low, bs_low |> format_vfo_freq())
          |> assign(:band_scope_high, bs_high |> format_vfo_freq())
        }

      msg |> String.starts_with?("SM") ->
        {:noreply, socket |> assign(:s_meter, msg |> format_s_meter())}

      msg |> String.starts_with?("FA") ->
        {:noreply, socket |> assign(:vfo_a_frequency, msg |> format_vfo_freq())}

      msg |> String.starts_with?("FB") ->
        {:noreply, socket |> assign(:vfo_b_frequency, msg |> format_vfo_freq())}

      msg |> String.starts_with?("BS3") ->
        band_scope_mode = msg
        |> String.trim_leading("BS3")
        |> case do
          "0" -> :center
          "1" -> :fixed
          "2" -> :auto_scroll
        end

        {:noreply, socket |> assign(:band_scope_mode, band_scope_mode)}

      msg == "FR0" ->
        {:noreply, socket |> assign(:active_receiver, :a) }

      msg == "FR1" ->
        {:noreply, socket |> assign(:active_receiver, :b) }

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

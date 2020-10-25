defmodule Open890Web.RadioLive do
  use Open890Web, :live_view
  require Logger
  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio

  alias Open890Web.RadioViewHelpers

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("LiveView mount()")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:audio_scope")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
    end

    Radio.get_active_receiver()
    Radio.get_band_scope_limits()
    Radio.get_band_scope_mode()
    Radio.get_vfo_a_freq()
    Radio.get_vfo_b_freq()
    Radio.get_s_meter()

    {:ok,
      socket
        |> assign(:s_meter, 0)
        |> assign(:vfo_a_frequency, "")
        |> assign(:vfo_b_frequency, "")
        |> assign(:band_scope_mode, nil)
        |> assign(:band_scope_low, nil)
        |> assign(:band_scope_high, nil)
        |> assign(:band_scope_span, "")
        |> assign(:projected_active_receiver_location, "")
        |> assign(:active_receiver, :a)
        |> assign(:active_transmitter, :a)
        |> assign(:band_scope_data, [])
        |> assign(:audio_scope_data, [])
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
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    zipped_data = (0..212)
    |> Enum.zip(audio_scope_data)
    |> Enum.map(fn {index, data} ->
      "#{index},#{data}"
     end)
     |> Enum.join(" ")


    {:noreply,
      socket |> assign(:audio_scope_data, zipped_data)
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
        [bs_low, bs_high] = msg |> extract_band_edges()

        [low_int, high_int] = [bs_low, bs_high]
        |> Enum.map(&String.to_integer/1)
        |> Enum.map(&Kernel.div(&1, 1000))

        span = (high_int - low_int) |> to_string() |> extract_frequency()

        {:noreply,
          socket
          |> assign(:band_scope_low, bs_low)
          |> assign(:band_scope_high, bs_high)
          |> assign(:band_scope_span, span)
        }

      msg |> String.starts_with?("SM") ->
        {:noreply, socket |> assign(:s_meter, msg |> format_s_meter())}

      msg |> String.starts_with?("FA") ->
          frequency = msg |> extract_frequency()

          socket = socket |> assign(:vfo_a_frequency, frequency)

          socket = if socket.assigns[:active_receiver] == :a do
            socket |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
          else
            socket
          end

        {:noreply, socket }

      msg |> String.starts_with?("FB") ->
        frequency = msg |> extract_frequency()

        socket = socket |> assign(:vfo_b_frequency, frequency)

        socket = if socket.assigns[:active_receiver] == :b do
          socket |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
        else
          socket
        end

        {:noreply, socket }

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

  defp extract_frequency(str) when is_binary(str) do
    str
    |> String.trim_leading("FA")
    |> String.trim_leading("FB")
    |> String.trim_leading("0")
  end

  defp format_s_meter(""), do: 0
  defp format_s_meter(str) when is_binary(str) do
    str
    |> String.trim_leading("SM")
    |> String.trim_leading("0")
    |> case do
      "" -> "0"
      val -> val
    end
    |> String.to_integer()
  end

  defp extract_band_edges("BSM0" <> low_high) do
    low_high
        |> String.split_at(8)
        |> Tuple.to_list()
  end
end

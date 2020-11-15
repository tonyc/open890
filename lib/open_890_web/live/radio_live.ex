defmodule Open890Web.RadioLive do
  use Open890Web, :live_view
  require Logger
  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio
  alias Open890.Extract

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
    Radio.get_modes()
    Radio.get_filter_modes()
    Radio.get_filter_state()
    # Radio.get_filter_settings()

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
     |> assign(:active_mode, :unknown)
     |> assign(:inactive_mode, :unknown)
     |> assign(:ssb_filter_mode, nil)
     |> assign(:ssb_data_filter_mode, nil)
     |> assign(:filter_hi_shift, nil)
     |> assign(:filter_lo_width, nil)}
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
    {:noreply, socket |> assign(:theme, theme_name)}
  end

  @impl true
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    zipped_data =
      0..212
      |> Enum.zip(audio_scope_data)
      |> Enum.map(fn {index, data} ->
        "#{index},#{data}"
      end)
      |> Enum.join(" ")

    {:noreply, socket |> assign(:audio_scope_data, zipped_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: %{payload: band_data}}, socket) do
    zipped_data =
      0..640
      |> Enum.zip(band_data)
      |> Enum.map(fn {index, data} ->
        "#{index},#{data}"
      end)
      |> Enum.join(" ")

    {
      :noreply,
      # socket |> push_event(:band_scope_data, payload)
      socket |> assign(:band_scope_data, zipped_data)
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    cond do
      msg |> String.starts_with?("BSM0") ->
        [bs_low, bs_high] = msg |> Extract.band_edges()

        [low_int, high_int] =
          [bs_low, bs_high]
          |> Enum.map(&Kernel.div(&1, 1000))

        span =
          (high_int - low_int)
          |> to_string()
          |> String.trim_leading("0")

        {:noreply,
         socket
         |> assign(:band_scope_low, bs_low)
         |> assign(:band_scope_high, bs_high)
         |> assign(:band_scope_span, span)}

      msg |> String.starts_with?("OM0") ->
        mode = msg |> Extract.operating_mode()

        socket = socket |> assign(:active_mode, mode)

        {:noreply, socket}

      msg |> String.starts_with?("OM1") ->
        mode = msg |> Extract.operating_mode()

        socket = socket |> assign(:inactive_mode, mode)

        {:noreply, socket}

      msg |> String.starts_with?("SM") ->
        s_meter_value = msg |> Extract.s_meter()

        socket = socket |> assign(:s_meter, s_meter_value)

        {:noreply, socket}

      msg |> String.starts_with?("FA") ->
        frequency = msg |> Extract.frequency()
        socket = socket |> assign(:vfo_a_frequency, frequency)

        socket =
          if socket.assigns[:active_receiver] == :a do
            socket |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
          else
            socket
          end

        {:noreply, socket}

      msg |> String.starts_with?("FB") ->
        frequency = msg |> Extract.frequency()
        socket = socket |> assign(:vfo_b_frequency, frequency)

        socket =
          if socket.assigns[:active_receiver] == :b do
            socket |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
          else
            socket
          end

        {:noreply, socket}

      msg |> String.starts_with?("BS3") ->
        band_scope_mode = msg |> Extract.scope_mode()

        {:noreply, socket |> assign(:band_scope_mode, band_scope_mode)}

      # high/shift
      msg |> String.starts_with?("SH0") ->
        passband_id = msg |> Extract.passband_id()

        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_hi_shift = passband_id |> Extract.filter_hi_shift(filter_mode, current_mode)

        {:noreply, socket |> assign(:filter_hi_shift, filter_hi_shift)}

      # lo/width
      msg |> String.starts_with?("SL0") ->
        passband_id = msg |> Extract.passband_id()

        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_lo_width = passband_id |> Extract.filter_lo_width(filter_mode, current_mode)

        {:noreply, socket |> assign(:filter_lo_width, filter_lo_width)}

      # ssb/ssb+data filter modes
      msg |> String.starts_with?("EX00611") ->
        ssb_filter_mode = msg |> Extract.filter_mode()
        {:noreply, socket |> assign(:ssb_filter_mode, ssb_filter_mode)}

      msg |> String.starts_with?("EX00612") ->
        ssb_data_filter_mode = msg |> Extract.filter_mode()
        {:noreply, socket |> assign(:ssb_data_filter_mode, ssb_data_filter_mode)}

      msg == "FR0" ->
        {:noreply, socket |> assign(:active_receiver, :a)}

      msg == "FR1" ->
        {:noreply, socket |> assign(:active_receiver, :b)}

      true ->
        Logger.debug("RadioLive: unknown message: #{inspect(msg)}")
        {:noreply, socket}
    end
  end

  defp determine_filter_low(passband_id) when is_integer(passband_id) do
  end
end

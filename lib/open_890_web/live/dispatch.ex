defmodule Open890Web.Live.Dispatch do
  require Logger

  alias Open890.Extract
  alias Open890Web.RadioViewHelpers

  import Phoenix.LiveView, only: [assign: 3, push_event: 3]

  def dispatch("BSC0" <> _rest = msg, socket) do
    ref_level = msg |> Extract.ref_level()
    socket |> assign(:ref_level, ref_level)
  end

  def dispatch("BSD" <> _rest, socket) do
    socket |> push_event("clear_band_scope", %{})
  end

  def dispatch("BSM0" <> _rest = msg, socket) do
    [bs_low, bs_high] = msg |> Extract.band_edges()

    [low_int, high_int] =
      [bs_low, bs_high]
      |> Enum.map(&Kernel.div(&1, 1000))

    span =
      (high_int - low_int)
      |> to_string()
      |> String.trim_leading("0")
      |> String.to_integer()

    socket
    |> assign(:band_scope_edges, {bs_low, bs_high})
    |> assign(:band_scope_span, span)
  end

  def dispatch("BS3" <> _rest = msg, socket) do
    socket |> assign(:band_scope_mode, Extract.scope_mode(msg))
  end

  def dispatch("BS8" <> _rest = msg, socket) do
    socket |> assign(:band_scope_att, Extract.band_scope_att(msg))
  end

  def dispatch("DS1" <> _rest = msg, socket) do
    socket |> assign(:display_screen_id, Extract.display_screen_id(msg))
  end

  def dispatch("EX00611" <> _rest = msg, socket) do
    socket
    |> assign(:ssb_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("EX00612" <> _rest = msg, socket) do
    socket
    |> assign(:ssb_data_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("FA" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> assign(:vfo_a_frequency, frequency)

    socket =
      if socket.assigns[:active_receiver] == :a do
        socket
        |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
        |> assign(:active_frequency, frequency)
      else
        socket
        |> assign(:inactive_frequency, frequency)
      end

    socket |> vfo_a_updated()
  end

  def dispatch("FB" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> assign(:vfo_b_frequency, frequency)

    socket =
      if socket.assigns[:active_receiver] == :b do
        socket
        |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
        |> assign(:active_frequency, frequency)
      else
        socket
        |> assign(:inactive_frequency, frequency)
      end

    socket
  end

  def dispatch("FR0", socket) do
    socket
    |> assign(:active_receiver, :a)
    |> assign(:active_frequency, socket.assigns.vfo_a_frequency)
    |> assign(:inactive_receiver, :b)
    |> assign(:inactive_frequency, socket.assigns.vfo_b_frequency)
  end

  def dispatch("FR1", socket) do
    socket
    |> assign(:active_receiver, :b)
    |> assign(:active_frequency, socket.assigns.vfo_b_frequency)
    |> assign(:inactive_receiver, :a)
    |> assign(:inactive_frequency, socket.assigns.vfo_a_frequency)
  end

  def dispatch("OM0" <> _rest = msg, socket) do
    socket |> assign(:active_mode, Extract.operating_mode(msg))
  end

  def dispatch("OM1" <> _rest = msg, socket) do
    socket |> assign(:inactive_mode, Extract.operating_mode(msg))
  end

  def dispatch("PA" <> _rest = msg, socket) do
    socket |> assign(:rf_pre, Extract.rf_pre(msg))
  end

  def dispatch("RA" <> _rest = msg, socket) do
    rf_att = msg |> Extract.rf_att()
    socket |> assign(:rf_att, rf_att)
  end

  def dispatch("RM1" <> _rest = msg, socket) do
    meter = msg |> Extract.alc_meter()
    socket |> assign(:alc_meter, meter)
  end

  def dispatch("RM2" <> _rest = msg, socket) do
    meter = msg |> Extract.swr_meter()
    socket |> assign(:swr_meter, meter)
  end

  def dispatch("RM3" <> _rest = msg, socket) do
    meter = msg |> Extract.comp_meter()
    socket |> assign(:comp_meter, meter)
  end

  def dispatch("RM4" <> _rest = msg, socket) do
    meter = msg |> Extract.id_meter()
    socket |> assign(:id_meter, meter)
  end

  def dispatch("RM5" <> _rest = msg, socket) do
    meter = msg |> Extract.vd_meter()
    socket |> assign(:vd_meter, meter)
  end

  def dispatch("RM6" <> _rest = msg, socket) do
    meter = msg |> Extract.temp_meter()
    socket |> assign(:temp_meter, meter)
  end

  def dispatch("SH0" <> _rest = msg, socket) do
    %{
      active_mode: current_mode,
      ssb_filter_mode: filter_mode
    } = socket.assigns

    filter_hi_shift =
      msg
      |> Extract.passband_id()
      |> Extract.filter_hi_shift(filter_mode, current_mode)

    socket
    |> assign(:filter_hi_shift, filter_hi_shift)
    |> update_filter_hi_edge()
  end

  def dispatch("SL0" <> _rest = msg, socket) do
    %{
      active_mode: current_mode,
      ssb_filter_mode: filter_mode
    } = socket.assigns

    filter_lo_width =
      msg
      |> Extract.passband_id()
      |> Extract.filter_lo_width(filter_mode, current_mode)

    socket
    |> assign(:filter_lo_width, filter_lo_width)
    |> update_filter_lo_edge()
  end

  def dispatch("SM" <> _rest = msg, socket) do
    socket |> assign(:s_meter, Extract.s_meter(msg))
  end

  ## dispatch catchall - this needs to be the very last one
  def dispatch(msg, socket) do
    Logger.debug("Dispatch: unknown message: #{inspect(msg)}")

    socket
  end

  ### END dispatching

  ### everything under here is used by the dispatch functions
  defp vfo_a_updated(socket) do
    socket
    |> update_filter_hi_edge()
    |> update_filter_lo_edge()
  end

  defp update_filter_edges(socket) do
    socket
    |> update_filter_hi_edge()
    |> update_filter_lo_edge()
  end

  defp update_filter_hi_edge(socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_hi_shift: filter_hi_shift
    } = socket.assigns

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> assign(
          :filter_high_freq,
          RadioViewHelpers.offset_frequency(mode, active_frequency, filter_hi_shift)
        )

      _ ->
        socket
    end
  end

  defp update_filter_lo_edge(socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_lo_width: filter_lo_width
    } = socket.assigns

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> assign(
          :filter_low_freq,
          RadioViewHelpers.offset_frequency_reverse(mode, active_frequency, filter_lo_width)
        )

      _ ->
        socket
    end
  end

  defp get_active_receiver_frequency(socket) do
    socket.assigns.active_receiver
    |> case do
      :a -> socket.assigns.vfo_a_frequency
      :b -> socket.assigns.vfo_b_frequency
    end
  end

end

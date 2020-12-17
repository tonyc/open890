defmodule Open890Web.Live.BandscopeLive do
  use Open890Web, :live_view
  require Logger

  alias Phoenix.Socket.Broadcast
  alias Open890.Extract
  alias Open890.TCPClient, as: Radio

  @impl true
  def mount(_params, session, socket) do
    Logger.info("BandScopeLive.mount")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")

      Radio.get_band_scope_limits()
      Radio.get_band_scope_mode()
    end

    socket =
      socket
      |> assign(:band_scope_data, [])
      |> assign(:theme, session["theme"])
      |> assign(:band_scope_mode, nil)
      |> assign(:band_scope_edges, nil)
      |> assign(:band_scope_span, nil)
      |> assign(:active_frequency, session["active_frequency"])
      |> assign(:active_mode, session["active_mode"])
      |> assign(:filter_lo_width, session["filter_lo_width"])
      |> assign(:filter_hi_shift, session["filter_hi_shift_"])
      |> assign(:ssb_filter_mode, session["ssb_filter_mode"])
      |> assign(:ssb_data_filter_mode, session["ssb_data_filter_mode"])

    {:ok, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: %{payload: band_data}}, socket) do
    {:noreply,
     socket
     |> assign(:band_scope_data, band_data)}
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
         |> assign(:band_scope_edges, {bs_low, bs_high})
         |> assign(:band_scope_span, span)}

      msg |> String.starts_with?("BS3") ->
        band_scope_mode = msg |> Extract.scope_mode()

        {:noreply, socket |> assign(:band_scope_mode, band_scope_mode)}
      true ->
        {:noreply, socket}
    end
  end
end

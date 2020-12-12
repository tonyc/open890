defmodule Open890Web.Live.BandscopeLive do
  use Open890Web, :live_view

  require Logger

  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, session, socket) do
    Logger.info("BandScopeLive.mount")
    session |> IO.inspect(label: "bandscope session")
    socket.assigns |> IO.inspect(label: "socket assigns")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
    end

    socket =
      socket
      |> assign(:band_scope_data, [])
      |> assign(:theme, session["theme"])
      |> assign(:band_scope_mode, session["band_scope_mode"])
      |> assign(:band_scope_low, session["band_scope_low"])
      |> assign(:band_scope_high, session["band_scope_high"])
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
end

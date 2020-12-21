defmodule Open890Web.Live.RadioLiveEventHandling do
  @moduledoc """
  This module encapsulates any liveview-specific events, e.g. events
  originating from the user (clicks, etc)
  """

  defmacro __using__(_) do
    quote location: :keep do
      alias Open890.TCPClient, as: Radio
      alias Open890.Menu

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

      def handle_event("open_menu_by_id", %{"id" => menu_id} = _params, socket) do
        menu_id = menu_id |> String.to_integer()

        {:noreply, socket |> set_screen_id(menu_id)}
      end

      def handle_event("open_top_menu", _params, socket) do
        {:noreply, socket |> set_screen_id(Menu.top_menu_id())}
      end

      def handle_event("close_menu", _params, socket) do
        {:noreply, socket |> set_screen_id(0)}
      end

      def handle_event("scope_clicked", %{"x" => x} = _params, %{assigns: %{active_receiver: active_receiver, band_scope_edges: {scope_low, scope_high}}} = socket) do
        new_frequency = x
        |> screen_to_frequency({scope_low, scope_high})
        |> to_string()
        |> String.pad_leading(11, "0")

        active_receiver
        |> case do
          :a -> Radio.cmd("FA#{new_frequency}")
          :b -> Radio.cmd("FB#{new_frequency}")
          vfo ->
            Logger.debug("Unknown vfo: #{vfo}")
        end

        {:noreply, socket}
      end

      defp set_screen_id(socket, id) do
        socket |> assign(:display_screen_id, id)
      end
    end
  end

end

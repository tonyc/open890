defmodule Open890Web.Live.RadioLiveEventHandling do
  alias Open890.ConnectionCommands, as: Radio

  @moduledoc """
  This module encapsulates any liveview-specific events, e.g. events
  originating from the user (clicks, etc)
  """

  defmacro __using__(_) do
    quote location: :keep do
      alias Open890.TCPClient, as: Radio
      alias Open890.Menu

      def handle_event(
            "ref_level_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        with {parsed_number, _extra} <- params["refLevel"] |> Float.parse() do
          connection |> Radio.set_ref_level(parsed_number)
        else
          other ->
            Logger.info("Unable to parse ref level. Result: #{inspect(other)}")
        end

        {:noreply, socket}
      end

      @impl true
      def handle_event("mic_up", _params, %{assigns: %{radio_connection: connection}} = socket) do
        connection |> Radio.ch_up()
        {:noreply, socket}
      end

      @impl true
      def handle_event("mic_dn", _params, %{assigns: %{radio_connection: connection}} = socket) do
        connection |> Radio.ch_down()
        {:noreply, socket}
      end

      @impl true
      def handle_event(
            "multi_ch",
            %{"is_up" => true} = params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.freq_change(:up)

        {:noreply, socket}
      end

      @impl true
      def handle_event(
            "multi_ch",
            %{"is_up" => false} = params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.freq_change(:down)

        {:noreply, socket}
      end

      @impl true
      def handle_event(
            "cmd",
            %{"cmd" => cmd} = _params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.cmd(cmd)
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

      def handle_event(
            "scope_clicked",
            %{"x" => x, "width" => width} = _params,
            %{
              assigns: %{
                radio_connection: connection,
                active_receiver: active_receiver,
                band_scope_edges: {scope_low, scope_high}
              }
            } = socket
          ) do
        new_frequency =
          x
          |> screen_to_frequency({scope_low, scope_high}, width)
          |> to_string()
          |> String.pad_leading(11, "0")

        active_receiver
        |> case do
          :a ->
            connection |> Radio.cmd("FA#{new_frequency}")

          :b ->
            connection |> Radio.cmd("FB#{new_frequency}")

          vfo ->
            Logger.debug("Unknown vfo: #{vfo}")
        end

        {:noreply, socket}
      end

      def handle_event("cw_tune", _params, %{assigns: %{radio_connection: connection}} = socket) do
        connection |> Radio.cw_tune()
        {:noreply, socket}
      end

      defp set_screen_id(socket, id) do
        socket |> assign(:display_screen_id, id)
      end
    end
  end
end

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

      def handle_event("stop_voip", params, %{assigns: %{radio_connection: connection}} = socket) do
        connection |> Radio.stop_voip()
        {:noreply, socket}
      end

      def handle_event("start_voip", params, %{assigns: %{radio_connection: connection}} = socket) do
        connection |> Radio.start_voip()
        {:noreply, socket}
      end

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

      def handle_event(
            "spectrum_scale_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        with {value, _extra} <- params["value"] |> Float.parse() do
          {:noreply, socket |> assign(:spectrum_scale, value)}
        else
          other ->
            Logger.info("Unable to parse spectrum_scale: #{inspect(other)}")
            {:noreply, socket}
        end
      end

      def handle_event(
            "wf_speed_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        with {value, _extra} <- params["value"] |> Integer.parse() do
          {:noreply, socket |> assign(:waterfall_draw_interval, value)}
        else
          other ->
            Logger.info("Unable to parse wf interval: #{inspect(other)}")
            {:noreply, socket}
        end
      end

      def handle_event(
            "notch_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.set_notch_pos(params["value"])

        {:noreply, socket}
      end

      def handle_event(
            "audio_gain_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.set_audio_gain(params["value"])
        {:noreply, socket}
      end

      def handle_event("adjust_notch", %{"is_up" => is_up} = params, socket) do
        notch_freq = socket.assigns.radio_state.notch_state.frequency

        step =
          case is_up do
            true -> 5
            false -> -5
          end

        notch_freq = notch_freq + step

        notch_freq =
          case is_up do
            true -> min(notch_freq, 255)
            false -> max(notch_freq, 0)
          end

        socket.assigns.radio_connection |> Radio.set_notch_pos(notch_freq)

        {:noreply, socket}
      end

      def handle_event("adjust_audio_gain", %{"is_up" => is_up} = params, socket) do
        audio_gain = socket.assigns.radio_state.audio_gain

        step =
          case is_up do
            true -> 5
            false -> -5
          end

        new_audio_gain = audio_gain + step

        new_audio_gain =
          case is_up do
            true -> min(new_audio_gain, 255)
            false -> max(new_audio_gain, 0)
          end

        socket.assigns.radio_connection |> Radio.set_audio_gain(new_audio_gain)

        {:noreply, socket}
      end

      def handle_event("adjust_rf_gain", %{"is_up" => is_up} = params, socket) do
        rf_gain = socket.assigns.radio_state.rf_gain

        step =
          case is_up do
            true -> 5
            false -> -5
          end

        new_rf_gain = rf_gain + step

        new_rf_gain =
          case is_up do
            true -> min(new_rf_gain, 255)
            false -> max(new_rf_gain, 0)
          end

        socket.assigns.radio_connection |> Radio.set_rf_gain(new_rf_gain)

        {:noreply, socket}
      end

      def handle_event("adjust_rit_xit", %{"is_up" => is_up} = params, socket) do
        radio_connection = socket.assigns.radio_connection

        if is_up do
          radio_connection |> Radio.rit_xit_up()
        else
          radio_connection |> Radio.rit_xit_down()
        end

        {:noreply, socket}
      end

      def handle_event("adjust_sql", %{"is_up" => is_up} = params, socket) do
        squelch = socket.assigns.radio_state.squelch

        step =
          case is_up do
            true -> 5
            false -> -5
          end

        new_squelch = squelch + step

        squelch =
          case is_up do
            true -> min(new_squelch, 255)
            false -> max(new_squelch, 0)
          end

        socket.assigns.radio_connection |> Radio.set_squelch(squelch)

        {:noreply, socket}
      end

      def handle_event(
            "sql_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.set_squelch(params["value"])

        {:noreply, socket}
      end

      def handle_event(
            "rf_gain_changed",
            params,
            %{assigns: %{radio_connection: connection}} = socket
          ) do
        connection |> Radio.set_rf_gain(params["value"])

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
                radio_state: radio_state,
                radio_connection: connection
              }
            } = socket
          ) do
        %{
          active_receiver: active_receiver,
          band_scope_edges: {scope_low, scope_high}
        } = radio_state

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

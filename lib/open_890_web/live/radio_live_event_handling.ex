defmodule Open890Web.Live.RadioLiveEventHandling do
  @moduledoc """
  This module encapsulates any liveview-specific events, e.g. events
  originating from the user (clicks, etc)
  """

  defmacro __using__(_) do
    quote location: :keep do
      alias Open890.TCPClient, as: Radio

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
    end
  end

end

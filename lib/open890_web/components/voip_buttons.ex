defmodule Open890Web.Components.VoipButtons do
  use Phoenix.Component

  attr :enabled, :boolean, required: true

  def mic_button(assigns) do
    ~H"""
      <%= if @enabled do %>
        <span class="ui small green button" phx-click="toggle_mic">
          <i class="icon microphone"></i> VOIP Mic: ON
        </span>
      <% else %>
        <span class="ui small red inverted button" phx-click="toggle_mic">
          <i class="icon microphone slash"></i> VOIP Mic: OFF
        </span>
      <% end %>
    """
  end
end

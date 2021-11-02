defmodule Open890Web.Live.NBIndicatorComponent do
  use Open890Web, :live_component

  alias Open890.NoiseBlankState

  def render(assigns) do
    ~H"""
      <div class="indicator nb">
        <%= if NoiseBlankState.any_enabled?(@noise_blank_state) do %>
          NB
          <%= if @noise_blank_state.nb_1_enabled do %>
            <span class="inverted">1</span>
          <% end %>
          <%= if @noise_blank_state.nb_2_enabled do %>
            <span class="inverted">2</span>
          <% end %>
        <% end %>
        &nbsp;
      </div>
    """
  end
end

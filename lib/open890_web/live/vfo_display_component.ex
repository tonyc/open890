defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  alias Open890Web.Live.BandIndicatorComponent
  alias Open890.BandRegisterState

  def render(assigns) do
    ~L"""
      <div class="vfos ui stackable compact grid">

        <div class="row compact ">
          <div class="seven wide right aligned column">
            <span class="vfoMemIndicator"><%= format_vfo_memory_state(@vfo_memory_state) %></span>
            <span class="modeIndicator active"><%= format_mode(@active_mode) %></span>
            <div class="freq active" phx-hook="ActiveVFO" id="ActiveVFO">
              <%= vfo_display_frequency(@active_frequency, @transverter_state) %>
            </div>
            <div class="bandRegister">BAND <span class="register"><%= band_for(@band_register_state, @active_receiver) %></span></div>
          </div>
          <div class="two wide center aligned column">
            <%= live_component @socket, BandIndicatorComponent, active_receiver: @active_receiver %>
          </div>
          <div class="seven wide left aligned column computer only tablet only">
            <span><%= format_mode(@inactive_mode) %></span>
            <div class="freq inactive"><%= vfo_display_frequency(@inactive_frequency, @transverter_state) %></div>
            <div class="bandRegister inactive">BAND <span class="register"><%= band_for(@band_register_state, @inactive_receiver) %></span></div>
          </div>
        </div>
      </div>
    """
  end

  def format_vfo_memory_state(state) do
    case state do
      :vfo -> "VFO"
      :memory -> "MEM"
      _ -> "UNKNOWN"
    end
  end

  def band_for(band_register_state, receiver) do
    band_register_state |> BandRegisterState.band_for(receiver)
  end
end

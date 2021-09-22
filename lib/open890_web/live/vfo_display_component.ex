defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  alias Open890Web.Live.BandIndicatorComponent
  alias Open890.{BandRegisterState, NotchState}

  def render(assigns) do
    ~L"""
      <div class="vfos ui stackable compact grid ">
        <div class="row compact">
          <div class="seven wide column">
            <div class="ui grid">

              <div class="row">

                <span class="vfoMemIndicator"><%= format_vfo_memory_state(@vfo_memory_state) %></span>
                <span class="modeIndicator active"><%= format_mode(@active_mode) %></span>
                <div class="freq active" phx-hook="ActiveVFO" id="ActiveVFO">
                  <%= vfo_display_frequency(@active_frequency, @transverter_state) %>
                </div>



              </div>


              <div class="row ">
                <div class="eight wide left aligned column">

                  <%= if @notch_state.enabled do %>
                    <span class="notchIndicator">
                      NOTCH
                      <span class="notchWidth inverted"><%= format_notch_width(@notch_state) %></span>
                    </span>
                  <% else %>
                    &nbsp;
                  <% end %>
                </div>
                <div class="eight wide right aligned column">
                  <span class="bandRegister">
                    BAND <span class="register inverted"><%= band_for(@band_register_state, @active_receiver) %></span>
                  </span>
                </div>
              </div>
            </div>

          </div> <!-- // end left side grid -->


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

  def format_notch_width(%NotchState{width: width} = _notch_state) do
    case width do
      :narrow -> "N"
      :mid -> "M"
      :wide -> "W"
      _ -> ""
    end
  end
end

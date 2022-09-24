defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  alias Open890Web.Live.BandIndicatorComponent
  alias Open890.{BandRegisterState}

  def render(assigns) do
    ~L"""
      <div class="vfos ui stackable compact grid ">
        <div class="row compact">
          <div class="seven wide column">
            <div class="ui grid">

              <div class="row">
                <div class="two wide left aligned column">
                  <span class="modeIndicator indicator active"><%= format_mode(@active_mode) %></span>
                </div>
                <div class="two wide left aligned column">
                  <span class="vfoMemIndicator indicator"><%= format_vfo_memory_state(@vfo_memory_state) %></span>
                </div>
                <div class="twelve wide right aligned column">
                  <div class="freq active" phx-hook="ActiveVFO" id="ActiveVFO">
                    <%= vfo_display_frequency(@active_frequency, @transverter_state) %>
                  </div>
                </div>
              </div>


              <%= if @vfo_memory_state == :vfo do %>
                <div class="row">
                  <div class="eight wide left aligned column">
                  </div>
                  <div class="eight wide right aligned column">
                    <span class="bandRegister">
                      BAND <span class="register inverted"><%= band_for(@band_register_state, @active_receiver) %></span>
                    </span>
                  </div>
                </div>
              <% end %>
            </div>

          </div> <!-- // end left side grid -->


          <div class="two wide center aligned column">
            <%= live_component BandIndicatorComponent, active_receiver: @active_receiver %>
          </div>

          <div class="seven wide left aligned column computer only tablet only">
            <div class="ui grid">
              <div class="row">
                <div class="four wide left aligned column">
                  <span class="vfoMemIndicator indicator inactive"></span>
                  <span class="modeIndicator indicator inactive"><%= format_mode(@inactive_mode) %></span>
                </div>
                <div class="twelve wide right aligned column">
                  <div class="freq inactive">
                    <%= vfo_display_frequency(@inactive_frequency, @transverter_state) %>
                  </div>
                </div>
              </div>

              <%= if @vfo_memory_state == :vfo do %>
                <div class="row">
                  <div class="eight wide left aligned column">
                  </div>
                  <div class="eight wide right aligned column">
                    <span class="bandRegister">
                      BAND <span class="register inverted"><%= band_for(@band_register_state, @inactive_receiver) %></span>
                    </span>
                  </div>
                </div>
              <% end %>

            </div>
          </div>

        </div>
      </div>
    """
  end

  def format_vfo_memory_state(state) do
    case state do
      :vfo -> "VFO"
      :memory -> "M.CH"
      _ -> ""
    end
  end

  def band_for(band_register_state, receiver) do
    band_register_state |> BandRegisterState.band_for(receiver)
  end
end

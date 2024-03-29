defmodule Open890Web.Components.VFODisplayComponent do
  use Open890Web, :component

  alias Open890.BandRegisterState
  alias Open890Web.Components.BandIndicatorComponent
  alias Open890Web.Components.TxIndicator

  def vfo_display(assigns) do
    ~H"""
      <div class="vfos ui stackable compact grid">
        <div class="row compact">
          <div class="seven wide column">
            <div class="ui grid">

              <div class="row">

                <div class="two wide left aligned column">
                  <span class="modeIndicator indicator active"><%= format_mode(@active_mode) %></span>
                </div>

                <div class="two wide left aligned column">
                  <span class="vfoMemIndicator indicator">
                    <%= format_vfo_memory_state(@vfo_memory_state) %>
                    <%= if @vfo_memory_state == :memory do %>
                      <span class="vfo-display-component__memory-channel-number"><%= format_memory_channel(@memory_channel_number) %></span>
                    <% end %>
                  </span>
                </div>

                <div class="twelve wide right aligned column">
                  <div class="freq active" phx-hook="ActiveVFO" id="ActiveVFO">
                    <%= vfo_display_frequency(@active_frequency, @transverter_state) %>
                  </div>
                </div>
              </div>

              <div class="vfo-display-component__band-indicator row">
                <div class="eight wide left aligned column">
                  <%= if !@split_enabled do %>
                    <TxIndicator.tx_indicator state={@tx_state} />
                  <% end %>
                </div>
                <div class="eight wide right aligned column">
                  <span class="bandRegister">
                    <%= if @vfo_memory_state == :vfo do %>
                      BAND <span class="register inverted"><%= band_for(@band_register_state, @active_receiver) %></span>
                    <% else %>
                      &nbsp;
                    <% end %>
                  </span>
                </div>
              </div>
            </div>

          </div> <!-- // end left side grid -->


          <div class="two wide center aligned column">
            <BandIndicatorComponent.band_indicator
              active_receiver={@active_receiver}
              inactive_frequency={@inactive_frequency}
              vfo_memory_state={@vfo_memory_state}
            />
          </div>

          <div class="seven wide left aligned column computer only tablet only">
            <div class="ui compact grid">
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

              <div class="vfo-display-component__band-row-indicator row">
                <div class="eight wide left aligned column">
                  <%= if @split_enabled do %>
                    <TxIndicator.tx_indicator state={@tx_state} />
                  <% end %>
                </div>
                <div class="eight wide right aligned column">
                  <span class="bandRegister">
                    <%= if @vfo_memory_state == :vfo do %>
                      BAND <span class="register inverted"><%= band_for(@band_register_state, @inactive_receiver) %></span>
                    <% else %>
                      &nbsp;
                    <% end %>
                  </span>
                </div>
              </div>

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

  def format_memory_channel(num) when num in 0..99 do
    num
    |> to_string()
    |> String.pad_leading(2, "0")
  end

  def format_memory_channel(num) when num in 100..109 do
    p_num = num - 100
    "P#{p_num}"
  end

  def format_memory_channel(num) when num in 110..119 do
    p_num = num - 110
    "E#{p_num}"
  end

  def format_memory_channel(_), do: ""

  def band_for(band_register_state, receiver) do
    band_register_state |> BandRegisterState.band_for(receiver)
  end
end

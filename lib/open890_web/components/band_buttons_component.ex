defmodule Open890Web.Live.BandButtonsComponent do
  use Open890Web, :live_component
  import Open890Web.Components.Buttons

  def render(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="four wide column center aligned aligned">

            <div id="modeKeys" class="ui vertical buttons">
              <.cmd_button_2 cmd="MK0" class="large fluid">LSB/USB</.cmd_button_2>
              <.cmd_button_2 cmd="MK1" class="large fluid">CW/CW-R</.cmd_button_2>
              <.cmd_button_2 cmd="MK2" class="large fluid">FSK/PSK</.cmd_button_2>
              <.cmd_button_2 cmd="MK3" class="large fluid">FM/AM</.cmd_button_2>
              <.cmd_button_2 cmd="MK4" class="large fluid">FSK/FSK-R</.cmd_button_2>
              <.cmd_button_2 cmd="MK5" class="large fluid">PSK/PSK-R</.cmd_button_2>
            </div>

          </div>
          <div class="twelve wide column">

            <div class="ui equal width grid">
              <div class="row">
                <div class="column"><.cmd_button_2 cmd="BU000" class="large fluid">1.8</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU001" class="large fluid">3.5</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU002" class="large fluid">7</.cmd_button_2></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button_2 cmd="BU003" class="large fluid">10</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU004" class="large fluid">14</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU005" class="large fluid">18</.cmd_button_2></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button_2 cmd="BU006" class="large fluid">21</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU006" class="large fluid">24</.cmd_button_2></div>
                <div class="column"><.cmd_button_2 cmd="BU008" class="large fluid">28</.cmd_button_2></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button_2 cmd="BU010" class="large fluid">GEN</.cmd_button_2></div>
                <div class="column"></div>
                <div class="column"><.cmd_button_2 cmd="BU009" class="large fluid">50</.cmd_button_2></div>
              </div>
            </div>

          </div>
        </div>
      </div>
    """
  end
end

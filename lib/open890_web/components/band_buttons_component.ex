defmodule Open890Web.Live.BandButtonsComponent do
  use Open890Web, :live_component
  import Open890Web.Components.Buttons

  def render(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="four wide column center aligned aligned">

            <div id="modeKeys" class="ui vertical buttons">
              <.cmd_button cmd="MK0" class="large fluid">LSB/USB</.cmd_button>
              <.cmd_button cmd="MK1" class="large fluid">CW/CW-R</.cmd_button>
              <.cmd_button cmd="MK2" class="large fluid">FSK/PSK</.cmd_button>
              <.cmd_button cmd="MK3" class="large fluid">FM/AM</.cmd_button>
              <.cmd_button cmd="MK4" class="large fluid">FSK/FSK-R</.cmd_button>
              <.cmd_button cmd="MK5" class="large fluid">PSK/PSK-R</.cmd_button>
            </div>

          </div>
          <div class="twelve wide column">

            <div class="ui equal width grid">
              <div class="row">
                <div class="column"><.cmd_button cmd="BU000" class="large fluid">1.8</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU001" class="large fluid">3.5</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU002" class="large fluid">7</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU003" class="large fluid">10</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU004" class="large fluid">14</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU005" class="large fluid">18</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU006" class="large fluid">21</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU006" class="large fluid">24</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU008" class="large fluid">28</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU010" class="large fluid">GEN</.cmd_button></div>
                <div class="column"></div>
                <div class="column"><.cmd_button cmd="BU009" class="large fluid">50</.cmd_button></div>
              </div>
            </div>

          </div>
        </div>
      </div>
    """
  end
end

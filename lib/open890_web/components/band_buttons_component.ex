defmodule Open890Web.Live.BandButtonsComponent do
  use Open890Web, :live_component
  import Open890Web.Components.Buttons

  def render(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="four wide column center aligned aligned">

            <div id="modeKeys" class="ui vertical large secondary buttons">
              <.cmd_button cmd="MK0">LSB/USB</.cmd_button>
              <.cmd_button cmd="MK1">CW/CW-R</.cmd_button>
              <.cmd_button cmd="MK2">FSK/PSK</.cmd_button>
              <.cmd_button cmd="MK3">FM/AM</.cmd_button>
              <.cmd_button cmd="MK4">FSK/FSK-R</.cmd_button>
              <.cmd_button cmd="MK5">PSK/PSK-R</.cmd_button>
            </div>

          </div>
          <div class="twelve wide column">

            <div class="ui equal width grid">
              <div class="row">
                <div class="column"><.cmd_button cmd="BU000" class="huge" fluid>1.8</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU001" class="huge" fluid>3.5</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU002" class="huge" fluid>7</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU003" class="huge" fluid>10</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU004" class="huge" fluid>14</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU005" class="huge" fluid>18</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU006" class="huge" fluid>21</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU007" class="huge" fluid>24</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU008" class="huge" fluid>28</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU010" class="huge" fluid>GEN</.cmd_button></div>
                <div class="column"></div>
                <div class="column"><.cmd_button cmd="BU009" class="huge" fluid>50</.cmd_button></div>
              </div>
            </div>

          </div>
        </div>
      </div>
    """
  end
end

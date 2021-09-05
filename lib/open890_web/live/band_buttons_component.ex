defmodule Open890Web.Live.BandButtonsComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="four wide column center aligned aligned">

            <div id="modeKeys" class="ui vertical buttons">
              <%= cmd_button "LSB/USB",   "MK0", class: "large fluid" %>
              <%= cmd_button "CW/CW-R",   "MK1", class: "large fluid" %>
              <%= cmd_button "FSK/PSK",   "MK2", class: "large fluid" %>
              <%= cmd_button "FM/AM",     "MK3", class: "large fluid" %>
              <%= cmd_button "FSK/FSK-R", "MK4", class: "large fluid" %>
              <%= cmd_button "PSK/PSK-R", "MK5", class: "large fluid" %>
            </div>

          </div>
          <div class="twelve wide column">

            <div class="ui equal width grid">
              <div class="row">
                <div class="column"><%= cmd_button "1.8", "BU000", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "3.5", "BU001", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "7", "BU002", class: "large fluid" %></div>
              </div>
              <div class="row">
                <div class="column"><%= cmd_button "10", "BU003", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "14", "BU004", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "18", "BU005", class: "large fluid" %></div>
              </div>
              <div class="row">
                <div class="column"><%= cmd_button "21", "BU006", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "24", "BU007", class: "large fluid" %></div>
                <div class="column"><%= cmd_button "28", "BU008", class: "large fluid" %></div>
              </div>
              <div class="row">
                <div class="column"><%= cmd_button "GEN", "BU010", class: "large fluid" %></div>
                <div class="column"></div>
                <div class="column"><%= cmd_button "50", "BU009", class: "large fluid" %></div>
              </div>
            </div>

          </div>
        </div>
      </div>
    """
  end
end

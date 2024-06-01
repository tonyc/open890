defmodule Open890Web.Components.ConnectionForm do
  use Phoenix.Component
  use Phoenix.HTML

  attr :f, :any, required: true
  def form_fields(assigns) do
    ~H"""
    <div class="required field">
      <%= label @f, :name, "Connection Name", class: "" %>
      <div class="ui huge input">
        <%= text_input @f, :name, required: true %>
      </div>
    </div>

    <div class="three fields">
      <div class="required field">
        <%= label @f, :ip_address, "IP Address", class: "" %>
        <div class="ui huge input">
          <%= text_input @f, :ip_address, required: true %>
        </div>
      </div>

      <div class="required field">
        <%= label @f, :tcp_port, "TCP Port" %>
        <div class="ui huge input">
          <%= text_input @f, :tcp_port, required: true %>
        </div>
      </div>

      <div class="field">
        <label for="radio_connection_mac_address">
          MAC Address
          <span data-inverted="" data-position="bottom center" data-tooltip="Enables wake-on-lan/remote power-on. Find in MENU -> MORE -> LAN.">
            <i class="question circle grey icon"></i>
          </span>
        </label>

        <div class="ui huge input">
          <%= text_input @f, :mac_address, pattern: "^([0-9A-Fa-f]{2}[:\\-]){5}([0-9A-Fa-f]{2})$", maxlength: 17, placeholder: "XX-XX-XX-XX-XX" %>
        </div>
      </div>
    </div>

    <div class="two fields">
      <div class="required field">
        <%= label @f, :user_name, "KNS User" %>
        <div class="ui huge input">
          <%= text_input @f, :user_name, required: true %>
        </div>
      </div>

      <div class="required field">
        <%= label @f, :password, "KNS Password" %>
        <div class="ui huge input">
          <%= password_input @f, :password, value: @f.source["password"], required: true %>
        </div>
      </div>
    </div>

      <div class="field">
        <div class="ui checkbox">
          <%= checkbox @f, :user_is_admin, class: "hidden", tabindex: "0" %>
          <%= label @f, :user_is_admin, "User is admin" %>
        </div>
      </div>

      <div class="field">
        <div class="ui checkbox">
          <%= checkbox @f, :auto_start, class: "hidden", tabindex: "0" %>
          <%= label @f, :auto_start, "Auto-Start" %>
        </div>
      </div>

    <div class="field">
      <div class="ui checkbox">
        <%= checkbox @f, :cloudlog_enabled, class: "hidden", tabindex: "0" %>
        <label for="radio_connection_cloudlog_enabled">
          Cloudlog Enabled
          <span data-inverted="" data-position="bottom center" data-tooltip="Send frequency/mode updates to a Cloudlog instance">
            <i class="question circle grey icon"></i>
          </span>
        </label>
      </div>
      <span>&mdash; <a href="https://github.com/tonyc/open890/wiki/Cloudlog-Integration" target="_blank">More information <i class="external alternate icon"></i></a></span>
    </div>

    <div class="field">
      <label for="radio_connection_cloudlog_url">
        <span class="hover-pointer" data-inverted="" data-position="right center" data-tooltip="The root URL of your Cloudlog instance, WITHOUT any path information, e.g. https://URCALL.cloudlog.co.uk">
          Cloudlog URL
          <i class="question circle grey icon"></i>
        </span>
      </label>
      <div class="ui huge input">
        <%= text_input @f, :cloudlog_url, placeholder: "https://<yourcall>.cloudlog.co.uk" %>
      </div>
    </div>

    <div class="field">
      <%= label @f, :cloudlog_api_key, "Cloudlog API key" %>
      <div class="ui huge input">
        <%= text_input @f, :cloudlog_api_key %>
      </div>
    </div>
    """
  end

end

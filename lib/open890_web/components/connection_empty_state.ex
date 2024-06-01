defmodule Open890Web.Components.ConnectionEmptyState do
  use Phoenix.Component
  alias Open890Web.Components.ConnectionForm

  def empty_state(assigns) do
    ~H"""
      <div id="emptyState" class="ui centered middle aligned grid">
        <div class="row">
          <div class="six wide left aligned column">
            <h1 class="">Welcome to open890!</h1>
          </div>
        </div>
        <div class="ui row">
          <div class="six wide left aligned column">
            <div class="">
              <p>It looks like you don't have any radio connections yet.  Let's get started by setting one up!</p>
              <p>Enter a connection name, the IP address of your radio, and the information that has been entered into the KNS menu (MENU ▶ KNS).</p>
            </div>
          </div>
        </div>
        <div class="ui grid row">
          <div class="six wide column">
            <div class="ui padded raised blue segment">
              <.form :let={f} for={%{"tcp_port" => 60_000}} as={:radio_connection} action="/connections" method="post" class="ui form">
                <ConnectionForm.form_fields f={f} />
                <button class="ui primary button" type="submit">Save Connection</button>
              </.form>
            </div>
          </div>
        </div>
      </div>
    """
  end
end

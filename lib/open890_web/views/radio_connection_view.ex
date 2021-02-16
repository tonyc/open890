defmodule Open890Web.RadioConnectionView do
  use Open890Web, :view
  alias Open890.RadioConnection

  def connection_to_uri(%RadioConnection{} = c) do
    "#{c.type}://#{c.user_name}@#{c.ip_address}"
  end
end

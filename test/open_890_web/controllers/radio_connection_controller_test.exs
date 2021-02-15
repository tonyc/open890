defmodule Open890Web.RadioConnectionControllerTest do
  use Open890Web.ConnCase

  alias Open890.RadioConnection

  @create_attrs %{
    name: "Test Radio Connection",
    ip_address: "10.0.0.2",
    user_name: "test_user",
    password: "testpass123",
    user_is_admin: false
  }

  def fixture(:radio_connection) do
    {:ok, radio_connection} = RadioConnection.create(@create_attrs)
    radio_connection
  end

  describe "index" do
    test "lists all connections", %{conn: conn} do
      conn = get(conn, Routes.radio_connection_path(conn, :index))

      assert html_response(conn, 200) =~ "Radio Connections"

      assert conn.assigns.radio_connections == []
    end
  end
end

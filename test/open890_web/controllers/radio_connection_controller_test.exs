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
    test "shows the onboarding screen when no connections exist", %{conn: conn} do
      assert RadioConnection.count_connections() == 0

      conn = get(conn, Routes.radio_connection_path(conn, :index))

      assert html_response(conn, 200) =~ "It looks like you don't have any radio connections yet"

      assert conn.assigns.radio_connections == []
    end

    # test "lists connections when they exist", %{conn: conn} do
    #   assert RadioConnection.count_connections() == 0

    #   radio_connection = fixture(:radio_connection)

    #   conn = get(conn, Routes.radio_connection_path(conn, :index))

    #   assert conn |> html_response(200) =~ "Radio connections"
    #   assert conn.assigns.radio_connections == [radio_connection]
    # end
  end

end

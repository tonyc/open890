defmodule Open890Web.Live.RadioTest do
  use Open890Web.ConnCase
  import Phoenix.LiveViewTest
  alias Open890.RadioConnection

  @endpoint Open890Web.Endpoint

  describe "GET /connections/:id" do
    setup do
      RadioConnection.delete_all()

      connection_params = %{
        "name" => "test",
        "ip_address" => "192.168.255.1",
        "tcp_port" => "60000",
        "user_name" => "testuser",
        "password" => "testpass",
        "auto_start" => false,
        "user_is_admin" => false
      }
      {:ok, radio_connection} = RadioConnection.create(connection_params)

      {:ok, %{radio_connection: radio_connection}}
    end

    test "disconnected and connected mount", %{radio_connection: radio_connection, conn: conn} do
      path = "/connections/#{radio_connection.id}"

      conn = get(conn, path)
      assert html_response(conn, 200)

      {:ok, _view, _html} = live(conn, path)
    end
  end

end

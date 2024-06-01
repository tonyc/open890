defmodule Open890Web.Router do
  require Logger
  use Open890Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Open890Web.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth_required do
    plug :http_basic_auth
  end

  scope "/", Open890Web do
    pipe_through [:browser, :auth_required]

    get "/", PageController, :index

    resources "/connections", RadioConnectionController, except: [:index, :show]

    live "/connections", Live.Connections, :index
    live "/connections/:id", Live.Radio, :show
    live "/connections/:id/bandscope", Live.Bandscope, :show
    live "/connections/:id/audioscope", Live.AudioScope, :show
    live "/connections/:id/meter", Live.Meter, :show
  end

  defp http_basic_auth(conn, _opts) do
    with {:ok, file} <- File.read("config/config.toml"),
         {:ok, config} <- Toml.decode(file) do
      auth_config = config |> get_in(["http", "server", "basic_auth"]) || %{}

      if auth_config |> Map.get("enabled", false) do
        username = auth_config["username"]
        password = auth_config["password"]

        if username == "" || password == "" do
          Logger.warn(
            "HTTP basic authentication IS NOT enabled. You enabled it, but supplied an empty username or password. Set these to non-empty strings to enable basic auth."
          )

          conn
        else
          Logger.info("HTTP basic auth plug")
          conn |> Plug.BasicAuth.basic_auth(username: username, password: password)
        end
      else
        Logger.info("Auth not enabled, skipping")
        conn
      end
    else
      _ -> conn
    end
  end
end

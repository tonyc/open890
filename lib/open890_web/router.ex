defmodule Open890Web.Router do
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

  scope "/", Open890Web do
    pipe_through :browser

    get "/", PageController, :index

    get "/connections", RadioConnectionController, :index
    get "/connections/new", RadioConnectionController, :new
    post "/connections", RadioConnectionController, :create
    get "/connections/:id/edit", RadioConnectionController, :edit
    post "/connections/:id", RadioConnectionController, :update

    post "/connections/:id/start", RadioConnectionController, :start
    post "/connections/:id/stop", RadioConnectionController, :stop

    live "/connections/:id", Live.RadioLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Open890Web do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: Open890Web.Telemetry
    end
  end
end

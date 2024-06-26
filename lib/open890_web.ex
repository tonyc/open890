defmodule Open890Web do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use Open890Web, :controller
      use Open890Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      require Logger
      use Phoenix.Controller, namespace: Open890Web

      import Plug.Conn
      import Open890Web.Gettext
      alias Open890Web.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/open890_web/templates",
        namespace: Open890Web

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Open890Web.LayoutView, :live}

      alias Open890Web.Components
      alias Open890Web.RadioViewHelpers

      unquote(view_helpers())
    end
  end

  # live_components encapsulate markup, state and events
  # use this if you want to handle_event in the specific component
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  # components just encapsulate markup
  # use this if you don't need any handle_event etc callbacks
  def component do
    quote do
      use Phoenix.Component
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Open890Web.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import Open890Web.Gettext
      alias Open890Web.Router.Helpers, as: Routes

      import Open890Web.RadioViewHelpers

      alias Open890.RadioConnection

      import Phoenix.LiveView

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Open890Web.Endpoint,
        router: Open890Web.Router,
        statics: Open890Web.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

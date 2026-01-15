defmodule BeamlensWeb do
  @moduledoc """
  BeamLens Web Dashboard - A mountable Phoenix LiveView dashboard for monitoring
  BeamLens operators, notifications, and coordinator insights.

  ## Usage

  Add `:beamlens_web` as a dependency in your Phoenix application:

      {:beamlens_web, "~> 0.1"}

  Then mount the dashboard in your router:

      import BeamlensWeb.Router

      scope "/" do
        pipe_through :browser
        live_beamlens_dashboard "/dashboard"
      end

  Navigate to `/dashboard` to view the BeamLens monitoring dashboard.
  """

  @doc """
  Returns the static path for BeamlensWeb assets.
  """
  def static_paths, do: ~w(assets images)

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {BeamlensWeb.Layouts, :dashboard}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      alias Phoenix.LiveView.JS
    end
  end
end

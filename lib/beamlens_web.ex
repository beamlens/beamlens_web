defmodule BeamlensWeb do
  @moduledoc """
  BeamLens Web Dashboard - A mountable Phoenix LiveView dashboard for monitoring
  BeamLens operators, notifications, and coordinator insights.

  ## Usage

  Add `:beamlens_web` as a dependency in your Phoenix application:

      {:beamlens_web, "~> 0.1"}

  Add BeamlensWeb to your supervision tree:

      children = [
        BeamlensWeb
      ]

  Then mount the dashboard in your router:

      import BeamlensWeb.Router

      scope "/" do
        pipe_through :browser
        beamlens_web "/beamlens"
      end

  Navigate to `/beamlens` to view the BeamLens monitoring dashboard.

  ## Optional: AI-powered summaries

  To enable AI-powered summaries, configure a `client_registry`:

      children = [
        {BeamlensWeb, client_registry: %{
          primary: "MyClient",
          clients: [
            %{name: "MyClient", provider: "openai-generic", options: %{...}}
          ]
        }}
      ]

  When not configured, the chat interface displays raw analysis data.
  """

  @doc """
  Returns a child specification for starting BeamlensWeb in a supervision tree.

  ## Options

    * `:client_registry` - A map containing LLM client configuration

  ## Example

      {BeamlensWeb, client_registry: %{primary: "ZAI", clients: [...]}}
  """
  defdelegate child_spec(opts), to: BeamlensWeb.Application

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

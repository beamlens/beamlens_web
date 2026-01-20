#!/bin/bash
set -e

echo "🧪 Setting up integration test environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd test_integration

# Check if test_app already exists
if [ -d "test_app" ]; then
  echo -e "${YELLOW}test_app already exists. Removing...${NC}"
  rm -rf test_app
fi

echo "Creating new Phoenix app..."
mix new test_app --sup

cd test_app

echo "Updating mix.exs dependencies..."
cat > mix.exs << 'EOF'
defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TestApp.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:beamlens, "~> 0.2"},
      {:beamlens_web, path: "../../"}
    ]
  end
end
EOF

echo "Installing dependencies..."
mix deps.get

echo "Creating web modules..."
mkdir -p lib/test_app_web

# Create Endpoint
cat > lib/test_app_web/endpoint.ex << 'EOF'
defmodule TestAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_app

  plug Plug.Static,
    at: "/",
    from: :beamlens_web,
    gzip: false,
    only: ~w(assets images favicon.ico favicon-16.png favicon-32.png)

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, store: :cookie, key: "_test_app_key", signing_salt: "test_signing_salt"
  plug TestAppWeb.Router
end
EOF

# Create Router
cat > lib/test_app_web/router.ex << 'EOF'
defmodule TestAppWeb.Router do
  use Phoenix.Router
  import BeamlensWeb.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    beamlens_web "/beamlens"
  end
end
EOF

# Create Layouts
cat > lib/test_app_web/layouts.ex << 'EOF'
defmodule TestAppWeb.Layouts do
  use Phoenix.Component

  def render("root.html", assigns) do
    ~H"""
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <.live_title suffix=" - Test App">
          <%= assigns[:page_title] || "Test App" %>
        </.live_title>
        <link phx-track-static rel="stylesheet" href="/assets/app.css" />
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
EOF

# Create Error View
cat > lib/test_app_web/error_view.ex << 'EOF'
defmodule TestAppWeb.ErrorView do
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
EOF

# Create Web Module
cat > lib/test_app_web.ex << 'EOF'
defmodule TestAppWeb do
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: TestAppWeb.Layouts]
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/test_app_web",
        namespace: TestAppWeb
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def component do
    quote do
      use Phoenix.Component
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
EOF

# Update Application
cat > lib/test_app/application.ex << 'EOF'
defmodule TestApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      TestAppWeb.Endpoint,
      {Beamlens.Supervisor, []},
      BeamlensWeb.Application
    ]

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
EOF

# Create config
mkdir -p config
cat > config/config.exs << 'EOF'
import Config

config :test_app, TestAppWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "test_secret_key_base_for_integration_testing",
  render_errors: [view: TestAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: TestApp.PubSub

config :phoenix, :json_library, Jason
config :phoenix, :template_engines, phoenix_live_view: Phoenix.LiveView.Engine
EOF

echo "Testing compilation..."
if mix compile 2>&1 | grep -q "error"; then
  echo -e "${RED}❌ Compilation failed${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Compilation successful${NC}"
fi

echo ""
echo -e "${GREEN}✅ Integration test setup complete!${NC}"
echo ""
echo "To manually test the dashboard:"
echo "  cd test_integration/test_app"
echo "  mix phx.server"
echo "  Then visit http://localhost:4000/beamlens"
echo ""
echo "To cleanup:"
echo "  rm -rf test_integration/test_app"

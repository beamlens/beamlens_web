# Manual Integration Test Setup

This document describes the manual setup process for creating a test Phoenix app that uses BeamlensWeb.

## Step 1: Create Test App

```bash
cd test_integration
mix new test_app --sup
cd test_app
```

## Step 2: Update mix.exs Dependencies

Add to `deps()` in `mix.exs`:

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"},
    {:phoenix_html, "~> 4.0"},
    {:bandit, "~> 1.0"},
    {:jason, "~> 1.4"},
    {:beamlens, "~> 0.2"},
    {:beamlens_web, path: "../../"}  # Use local path for testing
  ]
end
```

## Step 3: Create Endpoint Module

Create `lib/test_app_web/endpoint.ex`:

```elixir
defmodule TestAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_app

  # Serve static assets from beamlens_web
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
```

## Step 4: Create Router Module

Create `lib/test_app_web/router.ex`:

```elixir
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
```

## Step 5: Update Application Module

Update `lib/test_app/application.ex`:

```elixir
defmodule TestApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      TestAppWeb.Endpoint,
      {Beamlens.Supervisor, []},  # Start beamlens
      BeamlensWeb.Application      # Start beamlens_web
    ]

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Define the web module
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

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
```

## Step 6: Create Config

Update `config/config.exs`:

```elixir
import Config

config :test_app, TestAppWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "test_secret_key_base_for_integration_testing",
  render_errors: [view: TestAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: TestApp.PubSub

config :phoenix, :json_library, Jason
```

## Step 7: Create Layouts Module

Create `lib/test_app_web/layouts.ex`:

```elixir
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
```

## Step 8: Create Error View

Create `lib/test_app_web/views/error_view.ex`:

```elixir
defmodule TestAppWeb.ErrorView do
  use TestAppWeb, :view

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
```

## Step 9: Test the Setup

```bash
# Install dependencies
mix deps.get

# Start the server
mix phx.server
```

Visit: http://localhost:4000/beamlens

## Expected Results

- Dashboard loads without errors
- CSS styles are applied (Warm Ember dark theme)
- Sidebar displays with navigation
- Events stream section visible
- No browser console errors

## Cleanup

```bash
cd ..
rm -rf test_app
```

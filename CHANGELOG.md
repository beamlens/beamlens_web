# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of BeamlensWeb dashboard for monitoring BeamLens operators
- Real-time event stream with filtering and search capabilities
- Operator status monitoring with state badges
- Coordinator status and iteration tracking
- Notification and insight quick filters
- Multi-node cluster support via ERPC
- JSON export functionality for analysis
- Light/dark/system theme support with custom "Warm Ember" themes
- Interactive skill analysis triggering
- Operator control (start/stop/restart)
- Timezone toggle for UTC/local time display
- Comprehensive test suite (43 tests covering stores and utilities)

### Dependencies
- phoenix ~> 1.7
- phoenix_live_view ~> 1.0
- phoenix_html ~> 4.0
- req ~> 0.5
- beamlens ~> 0.2

## [0.1.0] - TBD

### Added
- Initial release
- Mountable Phoenix LiveView dashboard
- ETS-based event, notification, and insight stores
- Real-time telemetry event subscription
- Pre-built static assets with Tailwind CSS and DaisyUI
- Apache 2.0 licensing

### Installation

Add `beamlens_web` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:beamlens_web, "~> 0.1.0"},
    {:phoenix, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"},
    {:jason, "~> 1.4"},
    {:bandit, "~> 1.0"}
  ]
end
```

Then mount the dashboard in your router:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import BeamlensWeb.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    beamlens_web "/dashboard"
  end
end
```

Finally, update your endpoint to serve static assets:

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug Plug.Static,
    at: "/",
    from: :beamlens_web,
    gzip: false,
    only: ~w(assets images favicon.ico favicon-16.png favicon-32.png)
end
```

And add BeamlensWeb to your application supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... your children ...
      BeamlensWeb.Application
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Documentation

Full documentation available at [https://github.com/beamlens/beamlens_web](https://github.com/beamlens/beamlens_web)

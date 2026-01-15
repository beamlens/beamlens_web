# BeamlensWeb

A Phoenix LiveView dashboard for monitoring BeamLens operators and coordinator activity. Provides real-time visibility into system health, notifications, and insights.

## Features

- Real-time event stream with filtering and search
- Operator status monitoring with state badges
- Coordinator status and iteration tracking
- Notification and insight quick filters
- Multi-node cluster support
- JSON export for analysis
- Light/dark/system theme support

## Installation

Add `beamlens_web` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:beamlens_web, "~> 0.1.0"}
  ]
end
```

### Configure your router

Add the dashboard route to your Phoenix router:

```elixir
import BeamlensWeb.Router

scope "/" do
  pipe_through :browser
  beamlens_web "/dashboard"
end
```

### Serve static assets

The library includes pre-built CSS. Configure your endpoint to serve static files from the library:

```elixir
# In your endpoint.ex
plug Plug.Static,
  at: "/",
  from: :beamlens_web,
  gzip: false,
  only: ~w(assets)
```

## Development

### Prerequisites

- Elixir 1.18+
- Node.js 18+ (for CSS development only)

### Setup

```bash
mix deps.get
```

### CSS Development

The dashboard uses Tailwind CSS 4 with DaisyUI 5. CSS source is in `assets/css/app.css` and builds to `priv/static/assets/app.css`.

```bash
# Install Node.js dependencies
cd assets && npm install

# Build CSS (one-time)
npm run build

# Watch mode for development
npm run watch

# Build minified for production
npm run build:minify
```

Or use the build script from the project root:

```bash
./scripts/build_css.sh          # Build
./scripts/build_css.sh --watch  # Watch mode
./scripts/build_css.sh --minify # Minified
```

### Theming

The dashboard includes custom "Warm Ember" themes:

- **Dark theme** (`warm-ember-dark`): Default, dark background with orange accents
- **Light theme** (`warm-ember-light`): Light background variant
- **System mode**: Follows OS color scheme preference

Theme selection is persisted to localStorage and can be changed via the dropdown in the header.

To customize themes, edit the CSS variables in `assets/css/app.css`:

```css
[data-theme="warm-ember-dark"] {
  --color-base-100: #0f1115;
  --color-primary: #FD4F00;
  /* ... */
}
```

### Running tests

```bash
mix test
```

## Architecture

```
lib/beamlens_web/
├── application.ex          # OTP application
├── endpoint.ex             # Phoenix endpoint
├── router.ex               # Routes
├── components/
│   ├── core_components.ex          # Shared UI components
│   ├── icons.ex                    # Icon components
│   ├── layouts.ex                  # Root/dashboard layouts
│   ├── sidebar_components.ex       # Sidebar navigation
│   ├── event_components.ex         # Event list/detail views
│   ├── coordinator_components.ex   # Coordinator status
│   ├── notification_components.ex  # Notification cards and filters
│   └── operator_components.ex      # Operator status display
├── live/
│   └── dashboard_live.ex   # Main dashboard LiveView
└── stores/
    ├── notification_store.ex # Notification state management
    ├── event_store.ex        # Event stream storage
    └── insight_store.ex      # Insight state management
```

## License

See LICENSE file.

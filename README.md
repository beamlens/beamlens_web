# BeamlensWeb

A Phoenix LiveView dashboard for monitoring BeamLens operators and coordinator activity. Provides real-time visibility into system health, notifications, and insights.

## Features

- Chat-based interface for triggering analysis with conversational UI
- Real-time event stream with filtering and search
- Operator status monitoring with state badges
- Coordinator status and iteration tracking
- Notification and insight quick filters
- Multi-node cluster support
- Markdown rendering for chat responses
- Ability to stop running analysis from the chat interface
- Inline error display with expandable technical details
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

### Add to supervision tree

Add BeamlensWeb to your application's supervision tree with optional LLM client configuration:

```elixir
children = [
  # ... your other children ...
  {BeamlensWeb, client_registry: %{
    primary: "anthropic",
    clients: [
      %{name: "anthropic", provider: :anthropic, options: [model: "claude-sonnet-4-20250514"]}
    ]
  }}
]
```

The `client_registry` option enables the chat interface to generate AI-powered summaries of analysis results. If not provided, the chat will display raw analysis data.

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

## Telemetry Events

BeamlensWeb emits telemetry events for observability:

### Dashboard Events

- `[:beamlens_web, :dashboard, :chat_analysis, :start]` - Chat analysis started
- `[:beamlens_web, :dashboard, :chat_analysis, :complete]` - Chat analysis completed
- `[:beamlens_web, :dashboard, :chat_analysis, :error]` - Chat analysis failed
- `[:beamlens_web, :dashboard, :trigger_analysis, :start]` - Trigger analysis started
- `[:beamlens_web, :dashboard, :trigger_analysis, :complete]` - Trigger analysis completed
- `[:beamlens_web, :dashboard, :trigger_analysis, :error]` - Trigger analysis failed
- `[:beamlens_web, :dashboard, :summarization, :start]` - Summarization started
- `[:beamlens_web, :dashboard, :summarization, :complete]` - Summarization completed
- `[:beamlens_web, :dashboard, :summarization, :error]` - Summarization failed

### Summarizer Events

- `[:beamlens_web, :summarizer, :error]` - Summarizer error (e.g., no client registry)
- `[:beamlens_web, :summarizer, :compaction, :start]` - Context compaction started
- `[:beamlens_web, :summarizer, :compaction, :complete]` - Context compaction completed
- `[:beamlens_web, :summarizer, :compaction, :error]` - Context compaction failed
- `[:beamlens_web, :summarizer, :llm_call, :error]` - LLM call failed

## Architecture

```
lib/beamlens_web/
├── application.ex          # OTP application
├── chat_message.ex         # Chat message struct
├── config.ex               # Runtime configuration (client_registry)
├── endpoint.ex             # Phoenix endpoint
├── router.ex               # Routes
├── summarizer.ex           # AI-powered analysis summarization
├── components/
│   ├── chat_components.ex         # Chat interface components
│   ├── core_components.ex         # Shared UI components
│   ├── icons.ex                   # Icon components
│   ├── layouts.ex                 # Root/dashboard layouts
│   ├── sidebar_components.ex      # Sidebar navigation
│   ├── trigger_components.ex      # Trigger analysis form
│   ├── event_components.ex        # Event list/detail views
│   ├── coordinator_components.ex  # Coordinator status
│   ├── notification_components.ex # Notification cards and filters
│   └── operator_components.ex     # Operator status display
├── live/
│   └── dashboard_live.ex   # Main dashboard LiveView
└── stores/
    ├── notification_store.ex # Notification state management
    ├── event_store.ex        # Event stream storage
    └── insight_store.ex      # Insight state management

priv/
└── baml_src/               # BAML function definitions for LLM calls
```

## License

See LICENSE file.

# BeamlensWeb

A real-time dashboard for Beamlens.

## Features

- Chat interface to manage Beamlens
- Real-time event tracing
- Coordinator and operator health monitoring
- Cluster support
- JSON export for analysis

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

## License

See LICENSE file.

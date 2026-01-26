# BeamlensWeb

> ⚠️ **Beta Software**: This package is in beta. APIs may change.

![BeamlensWeb Demo](docs/demo.gif)

A real-time dashboard for Beamlens.

## Features

- Chat interface to manage Beamlens
- Real-time event tracing
- Coordinator and operator health monitoring
- Filter events by operator with live status indicators
- Cluster support
- JSON export for analysis

## Installation (Beta)

Add `beamlens_web` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:beamlens_web, "~> 0.1.0-beta.2"}
  ]
end
```

### Configure your router

Add the dashboard route to your Phoenix router:

```elixir
import BeamlensWeb.Router

scope "/" do
  pipe_through :browser
  beamlens_web "/beamlens"
end
```

### Add to supervision tree

Add BeamlensWeb to your application's supervision tree:

```elixir
children = [
  # ... your other children ...
  BeamlensWeb
]
```

#### Optional: AI-powered summaries

To enable AI-powered summaries of analysis results, configure a `client_registry`:

```elixir
children = [
  # ... your other children ...
  {BeamlensWeb, client_registry: %{
    primary: "anthropic",
    clients: [
      %{name: "anthropic", provider: :anthropic, options: [model: "claude-haiku-4-5"]}
    ]
  }}
]
```

When `client_registry` is not configured, the chat interface displays raw analysis data instead of AI summaries. See the [Beamlens provider docs](https://hexdocs.pm/beamlens/providers.html) for more configuration examples.

## Telemetry Events

BeamlensWeb emits telemetry events for observability:

### Dashboard Events

- `[:beamlens_web, :dashboard, :chat_analysis, :start]` - Chat analysis started
- `[:beamlens_web, :dashboard, :chat_analysis, :complete]` - Chat analysis completed
- `[:beamlens_web, :dashboard, :chat_analysis, :error]` - Chat analysis failed
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

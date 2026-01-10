defmodule BeamlensWeb.EventComponents do
  @moduledoc """
  Components for displaying telemetry events in the dashboard.
  """

  use Phoenix.Component

  @doc """
  Renders a list of events with optional filtering.
  """
  attr(:events, :list, required: true)
  attr(:filter, :atom, default: nil)
  attr(:source_filter, :atom, default: nil)
  attr(:selected_event_id, :string, default: nil)

  def event_list(assigns) do
    ~H"""
    <div class="event-log">
      <%= if Enum.empty?(@events) do %>
        <div class="empty-state">
          <div class="empty-state-icon">📋</div>
          <p>No events recorded yet</p>
          <p style="font-size: 0.75rem; margin-top: 0.5rem;">
            Events will appear here as watchers and coordinator run
          </p>
        </div>
      <% else %>
        <div class="event-list">
          <%= for event <- @events do %>
            <.event_row event={event} expanded={@selected_event_id == event.id} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a single event row with expandable details.
  """
  attr(:event, :map, required: true)
  attr(:expanded, :boolean, default: false)

  def event_row(assigns) do
    ~H"""
    <div class={"event-row-container #{if @expanded, do: "expanded", else: ""}"}>
      <div
        class={"event-row #{if @expanded, do: "selected", else: ""}"}
        phx-click="select_event"
        phx-value-id={@event.id}
      >
        <span class="event-expand-icon">
          <%= if @expanded, do: "▼", else: "▶" %>
        </span>
        <span class="event-timestamp timestamp">
          <%= format_timestamp(@event.timestamp) %>
        </span>
        <span class={"event-type-badge badge-#{event_type_class(@event.event_type)}"}>
          <%= format_event_type(@event.event_type) %>
        </span>
        <span class="event-source">
          <%= format_source(@event.source) %>
        </span>
        <span class="event-details">
          <%= format_event_details(@event) %>
        </span>
        <%= if @event.trace_id do %>
          <span class="event-trace-id" title={"Trace: #{@event.trace_id}"}>
            <%= String.slice(@event.trace_id || "", 0..7) %>
          </span>
        <% end %>
      </div>
      <%= if @expanded do %>
        <.event_detail event={@event} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the expanded detail view for an event.
  """
  attr(:event, :map, required: true)

  def event_detail(assigns) do
    ~H"""
    <div class="event-detail">
      <div class="event-detail-grid">
        <div class="event-detail-section">
          <h4>Event Info</h4>
          <dl>
            <dt>ID</dt>
            <dd><code><%= @event.id %></code></dd>
            <dt>Timestamp</dt>
            <dd><%= format_full_timestamp(@event.timestamp) %></dd>
            <dt>Event Name</dt>
            <dd><code><%= inspect(@event.event_name) %></code></dd>
            <dt>Type</dt>
            <dd><%= format_event_type(@event.event_type) %></dd>
            <dt>Source</dt>
            <dd><%= format_source(@event.source) %></dd>
            <%= if @event.trace_id do %>
              <dt>Trace ID</dt>
              <dd><code><%= @event.trace_id %></code></dd>
            <% end %>
          </dl>
        </div>
        <div class="event-detail-section">
          <h4>Metadata</h4>
          <%= if @event.metadata && map_size(@event.metadata) > 0 do %>
            <dl>
              <%= for {key, value} <- @event.metadata do %>
                <dt><%= key %></dt>
                <dd><%= format_metadata_value(value) %></dd>
              <% end %>
            </dl>
          <% else %>
            <p class="text-muted">No metadata</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders filter controls for the event list.
  """
  attr(:current_filter, :atom, default: nil)
  attr(:current_source, :atom, default: nil)
  attr(:sources, :list, default: [])
  attr(:paused, :boolean, default: false)

  def event_filters(assigns) do
    ~H"""
    <div class="event-filters">
      <form phx-change="filter_events" class="filter-form">
        <div class="filter-group">
          <label for="event-type-filter">Type:</label>
          <select id="event-type-filter" name="type">
            <option value="" selected={@current_filter == nil}>All Events</option>
            <option value="iteration_start" selected={@current_filter == :iteration_start}>Iterations</option>
            <option value="state_change" selected={@current_filter == :state_change}>State Changes</option>
            <option value="alert_fired" selected={@current_filter == :alert_fired}>Alerts Fired</option>
            <option value="take_snapshot" selected={@current_filter == :take_snapshot}>Snapshots</option>
            <option value="wait" selected={@current_filter == :wait}>Wait</option>
            <option value="think" selected={@current_filter == :think}>Think</option>
            <option value="llm_error" selected={@current_filter == :llm_error}>LLM Errors</option>
            <option value="alert_received" selected={@current_filter == :alert_received}>Alerts Received</option>
            <option value="insight_produced" selected={@current_filter == :insight_produced}>Insights</option>
            <option value="done" selected={@current_filter == :done}>Done</option>
          </select>
        </div>

        <div class="filter-group">
          <label for="event-source-filter">Source:</label>
          <select id="event-source-filter" name="source">
            <option value="" selected={@current_source == nil}>All Sources</option>
            <option value="coordinator" selected={@current_source == :coordinator}>Coordinator</option>
            <%= for source <- @sources do %>
              <option value={source} selected={@current_source == source}>
                <%= format_source(source) %>
              </option>
            <% end %>
          </select>
        </div>

        <button type="button" phx-click="clear_event_filters" class="filter-clear-btn">
          Clear
        </button>
      </form>

      <button
        type="button"
        phx-click="toggle_events_pause"
        class={"pause-btn #{if @paused, do: "paused", else: ""}"}
      >
        <%= if @paused do %>
          <span class="pause-icon">▶</span> Resume
        <% else %>
          <span class="pause-icon">⏸</span> Pause
        <% end %>
      </button>
    </div>
    """
  end

  # Private helper functions

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp format_full_timestamp(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S.%f")
  end

  defp format_metadata_value(value) when is_binary(value), do: value
  defp format_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp format_metadata_value(value) when is_number(value), do: to_string(value)
  defp format_metadata_value(value), do: inspect(value)

  defp format_event_type(:iteration_start), do: "ITERATION"
  defp format_event_type(:state_change), do: "STATE"
  defp format_event_type(:alert_fired), do: "ALERT"
  defp format_event_type(:take_snapshot), do: "SNAPSHOT"
  defp format_event_type(:wait), do: "WAIT"
  defp format_event_type(:think), do: "THINK"
  defp format_event_type(:llm_error), do: "ERROR"
  defp format_event_type(:alert_received), do: "RECEIVED"
  defp format_event_type(:insight_produced), do: "INSIGHT"
  defp format_event_type(:done), do: "DONE"
  defp format_event_type(type), do: type |> to_string() |> String.upcase()

  defp event_type_class(:iteration_start), do: "iteration"
  defp event_type_class(:state_change), do: "state"
  defp event_type_class(:alert_fired), do: "alert"
  defp event_type_class(:take_snapshot), do: "snapshot"
  defp event_type_class(:wait), do: "wait"
  defp event_type_class(:think), do: "think"
  defp event_type_class(:llm_error), do: "error"
  defp event_type_class(:alert_received), do: "received"
  defp event_type_class(:insight_produced), do: "insight"
  defp event_type_class(:done), do: "done"
  defp event_type_class(_), do: "default"

  defp format_source(:coordinator), do: "coordinator"
  defp format_source(:unknown), do: "unknown"
  defp format_source(source) when is_atom(source), do: Atom.to_string(source)
  defp format_source(source), do: to_string(source)

  defp format_event_details(%{event_type: :iteration_start, metadata: meta}) do
    "Iteration ##{meta[:iteration] || "?"} started (#{meta[:watcher_state] || "?"})"
  end

  defp format_event_details(%{event_type: :state_change, metadata: meta}) do
    "#{meta[:from]} → #{meta[:to]}" <>
      if(meta[:reason], do: " (#{truncate(meta[:reason], 30)})", else: "")
  end

  defp format_event_details(%{event_type: :alert_fired, metadata: meta}) do
    "#{meta[:severity]} alert: #{meta[:anomaly_type]}"
  end

  defp format_event_details(%{event_type: :take_snapshot, metadata: meta}) do
    "Captured snapshot #{String.slice(meta[:snapshot_id] || "", 0..7)}"
  end

  defp format_event_details(%{event_type: :wait, metadata: meta}) do
    "Sleeping #{meta[:ms]}ms"
  end

  defp format_event_details(%{event_type: :think, metadata: _meta}) do
    "Recorded thought"
  end

  defp format_event_details(%{event_type: :llm_error, metadata: meta}) do
    "LLM error: #{truncate(meta[:reason], 40)}"
  end

  defp format_event_details(%{event_type: :alert_received, metadata: meta}) do
    "Alert #{String.slice(meta[:alert_id] || "", 0..7)} from #{meta[:watcher]}"
  end

  defp format_event_details(%{event_type: :iteration_start, source: :coordinator, metadata: meta}) do
    "Analysis iteration ##{meta[:iteration]} (#{meta[:alert_count]} alerts)"
  end

  defp format_event_details(%{event_type: :insight_produced, metadata: meta}) do
    "Insight #{String.slice(meta[:insight_id] || "", 0..7)} (#{meta[:correlation_type]})"
  end

  defp format_event_details(%{event_type: :done, metadata: meta}) do
    "Analysis complete" <> if(meta[:has_unread], do: " (has unread)", else: "")
  end

  defp format_event_details(_event) do
    ""
  end

  defp truncate(nil, _max), do: ""

  defp truncate(str, max) when is_binary(str) do
    if String.length(str) > max do
      String.slice(str, 0, max) <> "..."
    else
      str
    end
  end

  defp truncate(other, max), do: truncate(inspect(other), max)
end

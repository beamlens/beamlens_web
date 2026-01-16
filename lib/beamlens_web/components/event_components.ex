defmodule BeamlensWeb.EventComponents do
  @moduledoc """
  Components for displaying telemetry events in the dashboard.
  """

  use Phoenix.Component

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.Icons

  @doc """
  Renders a list of events.
  """
  attr(:events, :list, required: true)
  attr(:selected_event_id, :string, default: nil)

  def event_list(assigns) do
    ~H"""
    <div class="bg-base-200 border border-base-300 rounded-lg flex-1 min-h-0 overflow-y-auto">
      <%= if Enum.empty?(@events) do %>
        <div class="text-center py-12 px-4 text-base-content/50">
          <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-3 opacity-50" />
          <p>No events recorded yet</p>
          <p class="text-xs mt-2">
            Events will appear here as operators and coordinator run
          </p>
        </div>
      <% else %>
        <div class="flex flex-col">
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
    <div class={[
      "border-b border-base-300 last:border-b-0",
      @expanded && "bg-base-100"
    ]}>
      <div
        class={[
          "group flex items-center gap-2 md:gap-3 px-3 md:px-4 py-2.5 text-sm cursor-pointer transition-colors hover:bg-base-300/50 min-w-0",
          @expanded && "bg-base-300/50"
        ]}
        phx-click="select_event"
        phx-value-id={@event.id}
      >
        <span class="text-base-content/50 shrink-0">
          <%= if @expanded do %>
            <.icon name="hero-chevron-down" class="w-4 h-4" />
          <% else %>
            <.icon name="hero-chevron-right" class="w-4 h-4" />
          <% end %>
        </span>
        <span class="font-mono text-xs text-base-content/50 shrink-0 hidden sm:inline">
          <.timestamp value={@event.timestamp} />
        </span>
        <span class={["badge badge-sm font-mono text-center shrink-0", event_badge_class(@event.event_type)]}>
          <%= format_event_type(@event.event_type) %>
        </span>
        <span class="text-base-content/70 font-medium shrink-0 hidden md:inline">
          <%= format_source(@event.source) %>
        </span>
        <span class={["text-base-content flex-1 min-w-0", if(@expanded, do: "whitespace-normal", else: "truncate")]}>
          <%= format_event_details(@event, @expanded) %>
        </span>
        <%= if @event.trace_id do %>
          <span class="font-mono text-xs text-base-content/50 shrink-0 hidden lg:inline" title={"Trace: #{@event.trace_id}"}>
            <%= String.slice(@event.trace_id || "", 0..7) %>
          </span>
        <% end %>
        <span class="shrink-0 opacity-0 group-hover:opacity-100 transition-opacity" onclick="event.stopPropagation()">
          <.copy_all_button data={@event} />
        </span>
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
    <div class="px-4 py-4 pl-10 bg-base-100 border-t border-base-300">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-3 pb-2 border-b border-base-300">
            Event Info
          </h3>
          <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
            <dt class="text-base-content/50 font-medium">ID</dt>
            <dd class="min-w-0"><div style="overflow: auto;"><.copyable value={@event.id} code={true} /></div></dd>
            <dt class="text-base-content/50 font-medium">Timestamp</dt>
            <dd class="min-w-0"><.timestamp value={@event.timestamp} format={:full} /></dd>
            <dt class="text-base-content/50 font-medium">Event Name</dt>
            <dd class="min-w-0"><div style="overflow: auto;"><.copyable value={inspect(@event.event_name)} code={true} /></div></dd>
            <dt class="text-base-content/50 font-medium">Type</dt>
            <dd class="min-w-0"><.copyable value={format_event_type(@event.event_type)} /></dd>
            <dt class="text-base-content/50 font-medium">Source</dt>
            <dd class="min-w-0"><.copyable value={format_source(@event.source)} /></dd>
            <%= if @event.trace_id do %>
              <dt class="text-base-content/50 font-medium">Trace ID</dt>
              <dd class="min-w-0"><div style="overflow: auto;"><.copyable value={@event.trace_id} code={true} /></div></dd>
            <% end %>
          </dl>
        </div>
        <div>
          <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-3 pb-2 border-b border-base-300">
            Metadata
          </h3>
          <%= if @event.metadata && map_size(@event.metadata) > 0 do %>
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
              <%= for {key, value} <- @event.metadata do %>
                <dt class="text-base-content/50 font-medium"><%= key %></dt>
                <dd class="text-base-content min-w-0">
                  <div class="max-h-32" style="overflow: auto;">
                    <.copyable value={format_metadata_value(value)} class="whitespace-pre" />
                  </div>
                </dd>
              <% end %>
            </dl>
          <% else %>
            <p class="text-base-content/50 italic text-sm">No metadata</p>
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
    <div class="flex items-center justify-between gap-4 mb-4">
      <form phx-change="filter_events" class="flex items-center gap-4 flex-wrap">
        <div class="flex items-center gap-2">
          <label for="event-type-filter" class="text-sm text-base-content/70">Type:</label>
          <select id="event-type-filter" name="type" class="select select-sm select-bordered">
            <option value="" selected={@current_filter == nil}>All Events</option>
            <option value="iteration_start" selected={@current_filter == :iteration_start}>Iterations</option>
            <option value="state_change" selected={@current_filter == :state_change}>State Changes</option>
            <option value="notification_sent" selected={@current_filter == :notification_sent}>Notifications Sent</option>
            <option value="take_snapshot" selected={@current_filter == :take_snapshot}>Snapshots</option>
            <option value="wait" selected={@current_filter == :wait}>Wait</option>
            <option value="think" selected={@current_filter == :think}>Think</option>
            <option value="llm_error" selected={@current_filter == :llm_error}>LLM Errors</option>
            <option value="notification_received" selected={@current_filter == :notification_received}>Notifications Received</option>
            <option value="insight_produced" selected={@current_filter == :insight_produced}>Insights</option>
            <option value="done" selected={@current_filter == :done}>Done</option>
          </select>
        </div>

        <div class="flex items-center gap-2">
          <label for="event-source-filter" class="text-sm text-base-content/70">Source:</label>
          <select id="event-source-filter" name="source" class="select select-sm select-bordered">
            <option value="" selected={@current_source == nil}>All Sources</option>
            <option value="coordinator" selected={@current_source == :coordinator}>Coordinator</option>
            <%= for source <- @sources do %>
              <option value={source} selected={@current_source == source}>
                <%= format_source(source) %>
              </option>
            <% end %>
          </select>
        </div>

        <button type="button" phx-click="clear_event_filters" class="btn btn-ghost btn-sm">
          Clear
        </button>
      </form>

      <button
        type="button"
        phx-click="toggle_events_pause"
        class={[
          "btn btn-sm gap-1",
          if(@paused, do: "btn-primary", else: "btn-ghost")
        ]}
      >
        <%= if @paused do %>
          <.icon name="hero-play" class="w-4 h-4" /> Resume
        <% else %>
          <.icon name="hero-pause" class="w-4 h-4" /> Pause
        <% end %>
      </button>
    </div>
    """
  end



  defp format_metadata_value(value) when is_binary(value), do: value
  defp format_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp format_metadata_value(value) when is_number(value), do: to_string(value)
  defp format_metadata_value(value), do: inspect(value)

  defp format_event_type(:iteration_start), do: "ITERATION"
  defp format_event_type(:state_change), do: "STATE"
  defp format_event_type(:notification_sent), do: "NOTIFICATION"
  defp format_event_type(:take_snapshot), do: "SNAPSHOT"
  defp format_event_type(:wait), do: "WAIT"
  defp format_event_type(:think), do: "THINK"
  defp format_event_type(:llm_error), do: "ERROR"
  defp format_event_type(:notification_received), do: "RECEIVED"
  defp format_event_type(:insight_produced), do: "INSIGHT"
  defp format_event_type(:done), do: "DONE"
  defp format_event_type(type), do: type |> to_string() |> String.upcase()

  defp event_badge_class(:iteration_start), do: "badge-primary"
  defp event_badge_class(:state_change), do: "badge-info"
  defp event_badge_class(:notification_sent), do: "badge-error"
  defp event_badge_class(:take_snapshot), do: "badge-secondary"
  defp event_badge_class(:wait), do: "badge-neutral"
  defp event_badge_class(:think), do: "badge-accent"
  defp event_badge_class(:llm_error), do: "badge-error"
  defp event_badge_class(:notification_received), do: "badge-warning"
  defp event_badge_class(:insight_produced), do: "badge-success"
  defp event_badge_class(:done), do: "badge-success"
  defp event_badge_class(_), do: "badge-neutral"

  defp format_source(:coordinator), do: "coordinator"
  defp format_source(:unknown), do: "unknown"
  defp format_source(source) when is_atom(source), do: Atom.to_string(source)
  defp format_source(source), do: to_string(source)

  defp format_event_details(event, expanded)

  defp format_event_details(
         %{event_type: :iteration_start, source: :coordinator, metadata: meta},
         _expanded
       ) do
    "Analysis iteration ##{meta[:iteration]} (#{meta[:notification_count]} notifications)"
  end

  defp format_event_details(%{event_type: :iteration_start, metadata: meta}, _expanded) do
    "Iteration ##{meta[:iteration] || "?"} started (#{meta[:operator_state] || "?"})"
  end

  defp format_event_details(%{event_type: :state_change, metadata: meta}, _expanded) do
    "#{meta[:from]} → #{meta[:to]}" <>
      if(meta[:reason], do: " (#{truncate(meta[:reason], 30)})", else: "")
  end

  defp format_event_details(%{event_type: :notification_sent, metadata: meta}, _expanded) do
    "#{meta[:severity]} notification: #{meta[:anomaly_type]}"
  end

  defp format_event_details(%{event_type: :take_snapshot, metadata: meta}, _expanded) do
    "Captured snapshot #{String.slice(meta[:snapshot_id] || "", 0..7)}"
  end

  defp format_event_details(%{event_type: :wait, metadata: meta}, _expanded) do
    "Sleeping #{meta[:ms]}ms"
  end

  defp format_event_details(%{event_type: :think, metadata: _meta}, _expanded) do
    "Recorded thought"
  end

  defp format_event_details(%{event_type: :llm_error, metadata: meta}, _expanded) do
    "LLM error: #{truncate(meta[:reason], 40)}"
  end

  defp format_event_details(%{event_type: :notification_received, metadata: meta}, _expanded) do
    operator_name = format_operator_name(meta[:operator])
    "Notification #{String.slice(meta[:notification_id] || "", 0..7)} from #{operator_name}"
  end

  defp format_event_details(%{event_type: :insight_produced, metadata: meta}, expanded) do
    if expanded do
      meta[:summary] || ""
    else
      truncate(meta[:summary], 80)
    end
  end

  defp format_event_details(%{event_type: :done, metadata: meta}, _expanded) do
    "Analysis complete" <> if(meta[:has_unread], do: " (has unread)", else: "")
  end

  defp format_event_details(_event, _expanded) do
    ""
  end

  defp format_operator_name(name) when is_atom(name) do
    name |> Module.split() |> List.last()
  end

  defp format_operator_name(name), do: to_string(name)

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

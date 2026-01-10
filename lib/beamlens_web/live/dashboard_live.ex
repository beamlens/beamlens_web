defmodule BeamlensWeb.DashboardLive do
  @moduledoc """
  Main LiveView for the BeamLens dashboard.

  Displays three tabs:
  - Watchers: Shows all active watchers with their states
  - Alerts: Shows alerts with filtering by status
  - Coordinator: Shows coordinator status and insights

  Supports cluster-wide monitoring via node selection.
  """

  use BeamlensWeb, :live_view

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.WatcherComponents
  import BeamlensWeb.AlertComponents
  import BeamlensWeb.CoordinatorComponents
  import BeamlensWeb.EventComponents

  @refresh_interval 5_000
  @rpc_timeout 5_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Monitor node connections/disconnections in real-time
      :net_kernel.monitor_nodes(true, node_type: :all)
      subscribe_to_telemetry()
      schedule_refresh()
    end

    {:ok,
     socket
     |> assign(:active_tab, :watchers)
     |> assign(:alert_filter, nil)
     |> assign(:event_type_filter, nil)
     |> assign(:event_source_filter, nil)
     |> assign(:selected_event_id, nil)
     |> assign(:events_paused, false)
     |> assign(:selected_node, Node.self())
     |> assign(:available_nodes, get_nodes())
     |> refresh_data()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("filter_alerts", %{"status" => ""}, socket) do
    {:noreply, assign(socket, :alert_filter, nil)}
  end

  def handle_event("filter_alerts", %{"status" => status}, socket) do
    {:noreply, assign(socket, :alert_filter, String.to_existing_atom(status))}
  end

  def handle_event("select_node", %{"node" => node_str}, socket) do
    node = String.to_existing_atom(node_str)
    {:noreply, socket |> assign(:selected_node, node) |> refresh_data()}
  end

  def handle_event("filter_events", params, socket) do
    type_filter =
      case params["type"] do
        "" -> nil
        type -> String.to_existing_atom(type)
      end

    source_filter =
      case params["source"] do
        "" -> nil
        "coordinator" -> :coordinator
        source -> String.to_existing_atom(source)
      end

    {:noreply,
     socket
     |> assign(:event_type_filter, type_filter)
     |> assign(:event_source_filter, source_filter)
     |> apply_event_filters()}
  end

  def handle_event("clear_event_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:event_type_filter, nil)
     |> assign(:event_source_filter, nil)
     |> apply_event_filters()}
  end

  def handle_event("select_event", %{"id" => id}, socket) do
    # Toggle selection - if clicking the same event, deselect it
    new_id = if socket.assigns.selected_event_id == id, do: nil, else: id
    {:noreply, assign(socket, :selected_event_id, new_id)}
  end

  def handle_event("toggle_events_pause", _params, socket) do
    paused = !socket.assigns.events_paused
    socket = assign(socket, :events_paused, paused)

    # When resuming, immediately refresh events to show latest
    socket = if not paused, do: refresh_events(socket), else: socket

    {:noreply, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, refresh_data(socket)}
  end

  def handle_info({:telemetry_event, _event_name, _data}, socket) do
    {:noreply, refresh_data(socket)}
  end

  # Handle node connections
  def handle_info({:nodeup, _node, _info}, socket) do
    {:noreply, assign(socket, :available_nodes, get_nodes())}
  end

  # Handle node disconnections
  def handle_info({:nodedown, node, _info}, socket) do
    socket = assign(socket, :available_nodes, get_nodes())

    # If the selected node went down, fall back to self
    socket =
      if socket.assigns.selected_node == node do
        socket
        |> assign(:selected_node, Node.self())
        |> refresh_data()
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="beamlens-dashboard">
      <header class="dashboard-header">
        <h1>
          <span class="logo">◉</span>
          BeamLens Dashboard
        </h1>
        <div class="header-status">
          <.node_selector
            selected_node={@selected_node}
            available_nodes={@available_nodes}
          />
          <span>Last updated: <%= format_time(@last_updated) %></span>
        </div>
      </header>

      <nav class="tab-nav">
        <button
          phx-click="switch_tab"
          phx-value-tab="watchers"
          class={["tab-btn", @active_tab == :watchers && "active"]}
        >
          Watchers (<%= length(@watchers) %>)
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="alerts"
          class={["tab-btn", @active_tab == :alerts && "active"]}
        >
          Alerts (<%= @alert_counts.total %>)
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="coordinator"
          class={["tab-btn", @active_tab == :coordinator && "active"]}
        >
          Coordinator
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="events"
          class={["tab-btn", @active_tab == :events && "active"]}
        >
          Events (<%= length(@events) %>)
        </button>
      </nav>

      <main class="dashboard-content">
        <%= case @active_tab do %>
          <% :watchers -> %>
            <.render_watchers_tab watchers={@watchers} />
          <% :alerts -> %>
            <.render_alerts_tab
              alerts={@filtered_alerts}
              counts={@alert_counts}
              current_filter={@alert_filter}
            />
          <% :coordinator -> %>
            <.render_coordinator_tab
              status={@coordinator_status}
              insights={@insights}
            />
          <% :events -> %>
            <.render_events_tab
              events={@filtered_events}
              event_type_filter={@event_type_filter}
              event_source_filter={@event_source_filter}
              event_sources={@event_sources}
              selected_event_id={@selected_event_id}
              paused={@events_paused}
            />
        <% end %>
      </main>
    </div>
    """
  end

  defp render_watchers_tab(assigns) do
    ~H"""
    <%= if Enum.empty?(@watchers) do %>
      <.empty_state icon="👁" message="No watchers are currently running" />
    <% else %>
      <.watcher_list watchers={@watchers} />
    <% end %>
    """
  end

  defp render_alerts_tab(assigns) do
    ~H"""
    <.alert_filters counts={@counts} current_filter={@current_filter} />
    <%= if Enum.empty?(@alerts) do %>
      <.empty_state icon="🔔" message="No alerts to display" />
    <% else %>
      <.alert_list alerts={@alerts} />
    <% end %>
    """
  end

  defp render_coordinator_tab(assigns) do
    ~H"""
    <h2 class="section-header">Coordinator Status</h2>
    <.coordinator_status status={@status} />

    <h2 class="section-header">Insights (<%= length(@insights) %>)</h2>
    <%= if Enum.empty?(@insights) do %>
      <.empty_state icon="💡" message="No insights have been produced yet" />
    <% else %>
      <.insight_list insights={@insights} />
    <% end %>
    """
  end

  defp render_events_tab(assigns) do
    ~H"""
    <.event_filters
      current_filter={@event_type_filter}
      current_source={@event_source_filter}
      sources={@event_sources}
      paused={@paused}
    />
    <.event_list events={@events} selected_event_id={@selected_event_id} />
    """
  end

  defp refresh_data(socket) do
    node = socket.assigns.selected_node

    watchers = fetch_watchers(node)
    alerts = fetch_alerts(node)
    alert_counts = fetch_alert_counts(node)
    insights = fetch_insights(node)
    coordinator_status = fetch_coordinator_status(node)

    filtered_alerts =
      case socket.assigns[:alert_filter] do
        nil -> alerts
        status -> Enum.filter(alerts, &(&1.status == status))
      end

    socket
    |> assign(:watchers, watchers)
    |> assign(:alerts, alerts)
    |> assign(:filtered_alerts, filtered_alerts)
    |> assign(:alert_counts, alert_counts)
    |> assign(:insights, insights)
    |> assign(:coordinator_status, coordinator_status)
    |> maybe_refresh_events()
    |> assign(:last_updated, DateTime.utc_now())
  end

  # Only refresh events if not paused
  defp maybe_refresh_events(socket) do
    if socket.assigns[:events_paused] do
      socket
    else
      refresh_events(socket)
    end
  end

  defp refresh_events(socket) do
    node = socket.assigns.selected_node
    events = fetch_events(node)

    # Extract unique sources from events (excluding :coordinator and :unknown)
    event_sources =
      events
      |> Enum.map(& &1.source)
      |> Enum.reject(&(&1 in [:coordinator, :unknown]))
      |> Enum.uniq()
      |> Enum.sort()

    socket
    |> assign(:events, events)
    |> assign(:event_sources, event_sources)
    |> apply_event_filters()
  end

  defp apply_event_filters(socket) do
    events = socket.assigns[:events] || []
    type_filter = socket.assigns[:event_type_filter]
    source_filter = socket.assigns[:event_source_filter]

    filtered =
      events
      |> maybe_filter_by_type(type_filter)
      |> maybe_filter_by_source(source_filter)

    assign(socket, :filtered_events, filtered)
  end

  defp maybe_filter_by_type(events, nil), do: events
  defp maybe_filter_by_type(events, type), do: Enum.filter(events, &(&1.event_type == type))

  defp maybe_filter_by_source(events, nil), do: events
  defp maybe_filter_by_source(events, source), do: Enum.filter(events, &(&1.source == source))

  # RPC-based data fetching functions

  defp fetch_watchers(node) do
    case rpc_call(node, Beamlens.Watcher.Supervisor, :list_watchers, []) do
      {:ok, watchers} -> watchers
      {:error, _reason} -> []
    end
  end

  defp fetch_alerts(node) do
    case rpc_call(node, BeamlensWeb.AlertStore, :alerts_callback, []) do
      {:ok, alerts} -> alerts
      {:error, _reason} -> []
    end
  end

  defp fetch_alert_counts(node) do
    case rpc_call(node, BeamlensWeb.AlertStore, :alert_counts_callback, []) do
      {:ok, counts} -> counts
      {:error, _reason} -> %{total: 0, unread: 0, acknowledged: 0, resolved: 0}
    end
  end

  defp fetch_insights(node) do
    case rpc_call(node, BeamlensWeb.InsightStore, :insights_callback, []) do
      {:ok, insights} -> insights
      {:error, _reason} -> []
    end
  end

  defp fetch_coordinator_status(node) do
    case rpc_call(node, Beamlens.Coordinator, :status, []) do
      {:ok, status} -> status
      {:error, _reason} -> %{running: false, alert_count: 0, unread_count: 0, iteration: 0}
    end
  end

  defp fetch_events(node) do
    case rpc_call(node, BeamlensWeb.EventStore, :events_callback, []) do
      {:ok, events} -> events
      {:error, _reason} -> []
    end
  end

  # Wrapper for :erpc.call with error handling
  defp rpc_call(node, module, function, args) do
    try do
      result = :erpc.call(node, module, function, args, @rpc_timeout)
      {:ok, result}
    catch
      :exit, {:exception, reason, _stack} ->
        {:error, reason}

      :exit, reason ->
        {:error, reason}
    end
  end

  defp get_nodes do
    [Node.self() | Node.list()]
  end

  defp subscribe_to_telemetry do
    pid = self()
    handler_id = "beamlens-dashboard-#{inspect(pid)}"

    events = [
      [:beamlens, :watcher, :state_change],
      [:beamlens, :watcher, :alert_fired],
      [:beamlens, :coordinator, :insight_produced],
      [:beamlens, :coordinator, :alert_received]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event_name, _measurements, _metadata, _config ->
        send(pid, {:telemetry_event, event_name, nil})
      end,
      nil
    )
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp format_time(%DateTime{} = dt) do
    Calendar.strftime(dt, "%H:%M:%S")
  end

  defp format_time(_), do: "-"
end

defmodule BeamlensWeb.DashboardLive do
  @moduledoc """
  Main LiveView for the BeamLens dashboard.

  Uses a sidebar + main panel layout:
  - Sidebar: Shows sources (watchers, coordinator) and quick filters (alerts, insights)
  - Main panel: Shows events filtered by selection, with cards for alerts/insights views

  Supports cluster-wide monitoring via node selection.
  """

  use BeamlensWeb, :live_view

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.CoordinatorComponents
  import BeamlensWeb.EventComponents
  import BeamlensWeb.Icons
  import BeamlensWeb.SidebarComponents

  @refresh_interval 5_000
  @rpc_timeout 5_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :net_kernel.monitor_nodes(true, node_type: :all)
      subscribe_to_telemetry()
      schedule_refresh()
    end

    {:ok,
     socket
     |> assign(:selected_source, :all)
     |> assign(:event_type_filter, nil)
     |> assign(:selected_event_id, nil)
     |> assign(:events_paused, false)
     |> assign(:selected_node, Node.self())
     |> assign(:available_nodes, get_nodes())
     |> refresh_data()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    source = parse_source_param(params["source"], socket.assigns.watchers)
    type_filter = parse_type_param(params["type"])

    {:noreply,
     socket
     |> assign(:selected_source, source)
     |> assign(:event_type_filter, type_filter)
     |> apply_filters()}
  end

  @impl true
  def handle_event("select_source", %{"source" => source}, socket) do
    source_atom = parse_source_string(source, socket.assigns.watchers)

    {:noreply,
     socket
     |> push_patch(to: build_url(source_atom, socket.assigns.event_type_filter))}
  end

  def handle_event("filter_events", params, socket) do
    type_filter =
      case params["type"] do
        "" -> nil
        type -> String.to_existing_atom(type)
      end

    {:noreply,
     socket
     |> push_patch(to: build_url(socket.assigns.selected_source, type_filter))}
  end

  def handle_event("clear_event_filters", _params, socket) do
    {:noreply,
     socket
     |> push_patch(to: build_url(socket.assigns.selected_source, nil))}
  end

  def handle_event("select_node", %{"node" => node_str}, socket) do
    node = String.to_existing_atom(node_str)
    {:noreply, socket |> assign(:selected_node, node) |> refresh_data()}
  end

  def handle_event("select_event", %{"id" => id}, socket) do
    new_id = if socket.assigns.selected_event_id == id, do: nil, else: id
    {:noreply, assign(socket, :selected_event_id, new_id)}
  end

  def handle_event("toggle_events_pause", _params, socket) do
    paused = !socket.assigns.events_paused
    socket = assign(socket, :events_paused, paused)
    socket = if not paused, do: refresh_events(socket), else: socket
    {:noreply, socket}
  end

  def handle_event("export_data", _params, socket) do
    node = socket.assigns.selected_node

    export_data = %{
      exported_at: DateTime.utc_now(),
      node: node,
      events: fetch_events(node),
      alerts: fetch_alerts(node),
      insights: fetch_insights(node),
      metadata: %{
        selected_source: socket.assigns.selected_source,
        event_type_filter: socket.assigns.event_type_filter
      }
    }

    json = Jason.encode!(export_data, pretty: true)
    filename = "beamlens-export-#{format_timestamp_for_file()}.json"

    {:noreply, push_event(socket, "download", %{content: json, filename: filename})}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, refresh_data(socket)}
  end

  def handle_info({:telemetry_event, _event_name, _data}, socket) do
    {:noreply, refresh_data(socket)}
  end

  def handle_info({:nodeup, _node, _info}, socket) do
    {:noreply, assign(socket, :available_nodes, get_nodes())}
  end

  def handle_info({:nodedown, node, _info}, socket) do
    socket = assign(socket, :available_nodes, get_nodes())

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
    <div class="grid grid-cols-[220px_1fr] grid-rows-[auto_1fr] h-screen overflow-hidden">
      <header class="col-span-2 bg-base-200 border-b border-base-300 px-6 py-4 flex items-center justify-between">
        <h1 class="text-xl font-semibold flex items-center gap-2">
          <.icon name="hero-viewfinder-circle" class="w-6 h-6 text-primary" />
          BeamLens Dashboard
        </h1>
        <div class="flex items-center gap-4 text-sm text-base-content/70">
          <.node_selector
            selected_node={@selected_node}
            available_nodes={@available_nodes}
          />
          <span>Last updated: <%= format_time(@last_updated) %></span>
          <.theme_toggle />
          <button type="button" phx-click="export_data" class="btn btn-ghost btn-sm gap-1">
            <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
            Export
          </button>
        </div>
      </header>

      <.source_sidebar
        selected_source={@selected_source}
        watchers={@watchers}
        coordinator_status={@coordinator_status}
        alert_count={@alert_counts.total}
        insight_count={length(@insights)}
      />

      <main class="overflow-y-auto p-6 bg-base-100">
        <.main_panel
          selected_source={@selected_source}
          filtered_events={@filtered_events}
          event_type_filter={@event_type_filter}
          event_sources={@event_sources}
          selected_event_id={@selected_event_id}
          events_paused={@events_paused}
          alerts={@alerts}
          insights={@insights}
          coordinator_status={@coordinator_status}
        />
      </main>
    </div>
    """
  end

  # Main panel rendering based on selected source
  defp main_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 h-full">
      <.panel_header
        selected_source={@selected_source}
        event_type_filter={@event_type_filter}
        event_sources={@event_sources}
        events_paused={@events_paused}
      />

      <%= if @selected_source == :coordinator do %>
        <.coordinator_panel status={@coordinator_status} />
      <% end %>

      <.event_list events={@filtered_events} selected_event_id={@selected_event_id} />
    </div>
    """
  end

  defp panel_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-4 shrink-0">
      <h2 class="text-base font-semibold text-base-content"><%= panel_title(@selected_source) %></h2>
      <div class="flex items-center gap-4">
        <.event_type_filter
          current_filter={@event_type_filter}
          selected_source={@selected_source}
        />
        <button
          type="button"
          phx-click="toggle_events_pause"
          class={[
            "btn btn-sm gap-1",
            if(@events_paused, do: "btn-primary", else: "btn-ghost")
          ]}
        >
          <%= if @events_paused do %>
            <.icon name="hero-play" class="w-4 h-4" /> Resume
          <% else %>
            <.icon name="hero-pause" class="w-4 h-4" /> Pause
          <% end %>
        </button>
      </div>
    </div>
    """
  end

  defp event_type_filter(assigns) do
    ~H"""
    <form phx-change="filter_events" class="flex items-center gap-2">
      <label for="event-type-filter" class="text-sm text-base-content/70">Type:</label>
      <select id="event-type-filter" name="type" class="select select-sm select-bordered">
        <option value="" selected={@current_filter == nil}>All Types</option>
        <%= for {value, label} <- type_options(@selected_source) do %>
          <option value={value} selected={@current_filter == value}><%= label %></option>
        <% end %>
      </select>
      <button type="button" phx-click="clear_event_filters" class="btn btn-ghost btn-sm">
        Clear
      </button>
    </form>
    """
  end

  defp type_options(:alerts) do
    [
      {:alert_fired, "Alerts Fired"},
      {:alert_received, "Alerts Received"}
    ]
  end

  defp type_options(:insights) do
    [
      {:insight_produced, "Insights Produced"}
    ]
  end

  defp type_options(_) do
    [
      {:iteration_start, "Iterations"},
      {:state_change, "State Changes"},
      {:alert_fired, "Alerts Fired"},
      {:take_snapshot, "Snapshots"},
      {:wait, "Wait"},
      {:think, "Think"},
      {:llm_error, "LLM Errors"},
      {:alert_received, "Alerts Received"},
      {:insight_produced, "Insights"},
      {:done, "Done"}
    ]
  end

  defp coordinator_panel(assigns) do
    ~H"""
    <div class="shrink-0 max-h-72 overflow-y-auto">
      <.coordinator_status status={@status} />
    </div>
    """
  end

  defp panel_title(:all), do: "All Activity"
  defp panel_title(:alerts), do: "Alerts"
  defp panel_title(:insights), do: "Insights"
  defp panel_title(:coordinator), do: "Coordinator"
  defp panel_title(watcher) when is_atom(watcher), do: "#{format_watcher_name(watcher)} Activity"

  defp format_watcher_name(name) when is_atom(name) do
    name |> Atom.to_string() |> String.capitalize()
  end

  # URL building and parsing

  defp build_url(source, type_filter) do
    params =
      []
      |> maybe_add_param(:source, source_to_string(source))
      |> maybe_add_param(:type, type_to_string(type_filter))

    case params do
      [] -> "/dashboard"
      _ -> "/dashboard?" <> URI.encode_query(params)
    end
  end

  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, key, value), do: [{key, value} | params]

  defp source_to_string(:all), do: nil
  defp source_to_string(:alerts), do: "alerts"
  defp source_to_string(:insights), do: "insights"
  defp source_to_string(:coordinator), do: "coordinator"
  defp source_to_string(watcher) when is_atom(watcher), do: Atom.to_string(watcher)

  defp type_to_string(nil), do: nil
  defp type_to_string(type) when is_atom(type), do: Atom.to_string(type)

  defp parse_source_param(nil, _watchers), do: :all
  defp parse_source_param("all", _watchers), do: :all
  defp parse_source_param("alerts", _watchers), do: :alerts
  defp parse_source_param("insights", _watchers), do: :insights
  defp parse_source_param("coordinator", _watchers), do: :coordinator

  defp parse_source_param(source, watchers) do
    watcher_names = Enum.map(watchers, & &1.watcher)

    try do
      atom = String.to_existing_atom(source)
      if atom in watcher_names, do: atom, else: :all
    rescue
      ArgumentError -> :all
    end
  end

  defp parse_source_string(source, watchers), do: parse_source_param(source, watchers)

  defp parse_type_param(nil), do: nil

  defp parse_type_param(type) do
    try do
      String.to_existing_atom(type)
    rescue
      ArgumentError -> nil
    end
  end

  # Filtering logic

  defp apply_filters(socket) do
    events = socket.assigns[:events] || []
    selected_source = socket.assigns[:selected_source]
    type_filter = socket.assigns[:event_type_filter]

    filtered =
      events
      |> filter_by_source(selected_source)
      |> filter_by_type(type_filter)

    assign(socket, :filtered_events, filtered)
  end

  defp filter_by_source(events, :all), do: events

  defp filter_by_source(events, :coordinator),
    do: Enum.filter(events, &(&1.source == :coordinator))

  defp filter_by_source(events, :alerts) do
    Enum.filter(events, &(&1.event_type in [:alert_fired, :alert_received]))
  end

  defp filter_by_source(events, :insights) do
    Enum.filter(events, &(&1.event_type == :insight_produced))
  end

  defp filter_by_source(events, watcher) when is_atom(watcher) do
    Enum.filter(events, &(&1.source == watcher))
  end

  defp filter_by_type(events, nil), do: events
  defp filter_by_type(events, type), do: Enum.filter(events, &(&1.event_type == type))

  # Data fetching

  defp refresh_data(socket) do
    node = socket.assigns.selected_node

    watchers = fetch_watchers(node)
    alerts = fetch_alerts(node)
    alert_counts = fetch_alert_counts(node)
    insights = fetch_insights(node)
    coordinator_status = fetch_coordinator_status(node)

    socket
    |> assign(:watchers, watchers)
    |> assign(:alerts, alerts)
    |> assign(:alert_counts, alert_counts)
    |> assign(:insights, insights)
    |> assign(:coordinator_status, coordinator_status)
    |> maybe_refresh_events()
    |> assign(:last_updated, DateTime.utc_now())
  end

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

    event_sources =
      events
      |> Enum.map(& &1.source)
      |> Enum.reject(&(&1 in [:coordinator, :unknown]))
      |> Enum.uniq()
      |> Enum.sort()

    socket
    |> assign(:events, events)
    |> assign(:event_sources, event_sources)
    |> apply_filters()
  end

  # RPC-based data fetching

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

  defp format_timestamp_for_file do
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d-%H%M%S")
  end
end

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
     |> assign(:sidebar_open, false)
     |> assign(:settings_open, false)
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
     |> assign(:sidebar_open, false)
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

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  def handle_event("toggle_settings", _params, socket) do
    {:noreply, assign(socket, :settings_open, !socket.assigns.settings_open)}
  end

  def handle_event("close_settings", _params, socket) do
    {:noreply, assign(socket, :settings_open, false)}
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

  def handle_event("copy_to_clipboard", %{"text" => text, "copy-id" => copy_id}, socket) do
    {:noreply, push_event(socket, "copy", %{text: text, copyId: copy_id})}
  end

  def handle_event("copy_to_clipboard", %{"text" => text}, socket) do
    {:noreply, push_event(socket, "copy", %{text: text, copyId: nil})}
  end

  def handle_event("copy_record", %{"data" => data, "copy-id" => copy_id}, socket) do
    # Format JSON nicely for readability
    formatted =
      data
      |> Jason.decode!()
      |> Jason.encode!(pretty: true)

    {:noreply, push_event(socket, "copy", %{text: formatted, copyId: copy_id})}
  end

  def handle_event("copy_record", %{"data" => data}, socket) do
    # Format JSON nicely for readability
    formatted =
      data
      |> Jason.decode!()
      |> Jason.encode!(pretty: true)

    {:noreply, push_event(socket, "copy", %{text: formatted, copyId: nil})}
  end

  def handle_event("restart_watcher", %{"watcher" => watcher_str}, socket) do
    watcher = String.to_existing_atom(watcher_str)
    node = socket.assigns.selected_node

    # Stop and restart the watcher
    _ = rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [watcher])
    result = rpc_call(node, Beamlens.Operator.Supervisor, :start_operator, [watcher])

    socket =
      case result do
        {:ok, {:ok, _pid}} ->
          socket
          |> put_flash(:info, "Watcher #{watcher} restarted successfully")
          |> refresh_data()

        {:ok, {:error, reason}} ->
          put_flash(socket, :error, "Failed to restart #{watcher}: #{inspect(reason)}")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error restarting #{watcher}: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("stop_watcher", %{"watcher" => watcher_str}, socket) do
    watcher = String.to_existing_atom(watcher_str)
    node = socket.assigns.selected_node

    result = rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [watcher])

    socket =
      case result do
        {:ok, :ok} ->
          socket
          |> put_flash(:info, "Watcher #{watcher} stopped")
          |> refresh_data()

        {:ok, {:error, :not_found}} ->
          put_flash(socket, :error, "Watcher #{watcher} not found")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error stopping #{watcher}: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("start_all_watchers", _params, socket) do
    node = socket.assigns.selected_node
    watchers = socket.assigns.watchers

    stopped_watchers = Enum.reject(watchers, & &1.running)

    results =
      Enum.map(stopped_watchers, fn watcher ->
        {watcher.watcher,
         rpc_call(node, Beamlens.Operator.Supervisor, :start_operator, [watcher.watcher])}
      end)

    {successes, failures} =
      Enum.split_with(results, fn
        {_, {:ok, {:ok, _}}} -> true
        _ -> false
      end)

    socket =
      cond do
        Enum.empty?(stopped_watchers) ->
          put_flash(socket, :info, "All watchers are already running")

        Enum.empty?(failures) ->
          socket
          |> put_flash(:info, "Started #{length(successes)} watcher(s)")
          |> refresh_data()

        true ->
          failed_names = Enum.map(failures, fn {name, _} -> name end) |> Enum.join(", ")

          socket
          |> put_flash(:error, "Failed to start: #{failed_names}")
          |> refresh_data()
      end

    {:noreply, socket}
  end

  def handle_event("stop_all_watchers", _params, socket) do
    node = socket.assigns.selected_node
    watchers = socket.assigns.watchers

    running_watchers = Enum.filter(watchers, & &1.running)

    results =
      Enum.map(running_watchers, fn watcher ->
        {watcher.watcher,
         rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [watcher.watcher])}
      end)

    {successes, failures} =
      Enum.split_with(results, fn
        {_, {:ok, :ok}} -> true
        _ -> false
      end)

    socket =
      cond do
        Enum.empty?(running_watchers) ->
          put_flash(socket, :info, "All watchers are already stopped")

        Enum.empty?(failures) ->
          socket
          |> put_flash(:info, "Stopped #{length(successes)} watcher(s)")
          |> refresh_data()

        true ->
          failed_names = Enum.map(failures, fn {name, _} -> name end) |> Enum.join(", ")

          socket
          |> put_flash(:error, "Failed to stop: #{failed_names}")
          |> refresh_data()
      end

    {:noreply, socket}
  end

  def handle_event("start_coordinator", _params, socket) do
    node = socket.assigns.selected_node

    result =
      rpc_call(node, Supervisor, :restart_child, [Beamlens.Supervisor, Beamlens.Coordinator])

    socket =
      case result do
        {:ok, {:ok, _pid}} ->
          socket
          |> put_flash(:info, "Coordinator started")
          |> refresh_data()

        {:ok, {:error, :running}} ->
          put_flash(socket, :info, "Coordinator is already running")

        {:ok, {:error, reason}} ->
          put_flash(socket, :error, "Failed to start coordinator: #{inspect(reason)}")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error starting coordinator: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("stop_coordinator", _params, socket) do
    node = socket.assigns.selected_node

    result =
      rpc_call(node, Supervisor, :terminate_child, [Beamlens.Supervisor, Beamlens.Coordinator])

    socket =
      case result do
        {:ok, :ok} ->
          socket
          |> put_flash(:info, "Coordinator stopped")
          |> refresh_data()

        {:ok, {:error, :not_found}} ->
          put_flash(socket, :error, "Coordinator not found")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error stopping coordinator: #{inspect(reason)}")
      end

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
    <div class="flex flex-col h-screen overflow-hidden md:grid md:grid-cols-[220px_1fr] md:grid-rows-[auto_1fr]">
      <header class="md:col-span-2 bg-base-200 border-b border-base-300 px-4 py-3 md:px-6 md:py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <button
              type="button"
              phx-click="toggle_sidebar"
              class="btn btn-ghost btn-sm btn-square md:hidden"
              aria-label="Toggle sidebar"
            >
              <.icon name="hero-bars-3" class="w-5 h-5" />
            </button>
            <h1 class="text-lg md:text-xl font-semibold flex items-center gap-2">
              <.icon name="hero-viewfinder-circle" class="w-5 h-5 md:w-6 md:h-6 text-primary" />
              <span class="hidden sm:inline">BeamLens Dashboard</span>
              <span class="sm:hidden">BeamLens</span>
            </h1>
          </div>
          <%!-- Desktop header controls --%>
          <div class="hidden md:flex items-center gap-4 text-sm text-base-content/70">
            <.node_selector
              selected_node={@selected_node}
              available_nodes={@available_nodes}
            />
            <span class="hidden lg:inline">Last updated: <.timestamp value={@last_updated} /></span>
            <.timezone_toggle />
            <.theme_toggle />
            <button type="button" phx-click="export_data" class="btn btn-ghost btn-sm gap-1">
              <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
              Export
            </button>
          </div>
          <%!-- Mobile settings button --%>
          <button
            type="button"
            phx-click="toggle_settings"
            class="btn btn-ghost btn-sm btn-square md:hidden"
            aria-label="Open settings"
          >
            <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
          </button>
        </div>
      </header>

      <.source_sidebar
        selected_source={@selected_source}
        watchers={@watchers}
        coordinator_status={@coordinator_status}
        alert_count={@alert_counts.total}
        insight_count={length(@insights)}
        mobile_open={@sidebar_open}
      />

      <.settings_panel
        open={@settings_open}
        selected_node={@selected_node}
        available_nodes={@available_nodes}
        last_updated={@last_updated}
      />

      <main class="flex-1 overflow-y-auto p-4 md:p-6 bg-base-100">
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

  # Mobile settings panel (right drawer)
  defp settings_panel(assigns) do
    ~H"""
    <%!-- Backdrop --%>
    <div
      class={[
        "fixed inset-0 z-40 md:hidden",
        if(@open, do: "block", else: "hidden")
      ]}
      phx-click="close_settings"
    >
      <div class="absolute inset-0 bg-black/50"></div>
    </div>
    <%!-- Panel --%>
    <aside class={[
      "fixed inset-y-0 right-0 z-50 w-72 bg-base-200 border-l border-base-300 overflow-y-auto py-3 transition-transform duration-200 ease-in-out md:hidden",
      if(@open, do: "translate-x-0", else: "translate-x-full")
    ]}>
      <div class="flex items-center justify-between px-4 py-2 mb-4 border-b border-base-300">
        <span class="text-sm font-semibold text-base-content">Settings</span>
        <button
          type="button"
          phx-click="close_settings"
          class="btn btn-ghost btn-sm btn-square"
          aria-label="Close settings"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <div class="px-4 space-y-6">
        <%!-- Node selector --%>
        <div class="space-y-2">
          <label class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">Node</label>
          <form phx-change="select_node">
            <select name="node" class="select select-sm select-bordered w-full" aria-label="Select node">
              <%= for node <- @available_nodes do %>
                <option value={node} selected={@selected_node == node}>
                  <%= format_node_name(node) %>
                </option>
              <% end %>
            </select>
          </form>
        </div>

        <%!-- Last updated --%>
        <div class="space-y-2">
          <label class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">Last Updated</label>
          <div class="text-sm text-base-content">
            <.timestamp value={@last_updated} />
          </div>
        </div>

        <%!-- Timezone toggle --%>
        <div class="space-y-2">
          <label class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">Timezone</label>
          <.timezone_toggle />
        </div>

        <%!-- Theme selection --%>
        <div class="space-y-2">
          <label class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">Theme</label>
          <div class="flex gap-2">
            <button
              type="button"
              onclick="setTheme('light')"
              class="btn btn-sm btn-ghost flex-1 gap-1"
              aria-label="Light theme"
            >
              <.icon name="hero-sun" class="w-4 h-4" />
              Light
            </button>
            <button
              type="button"
              onclick="setTheme('dark')"
              class="btn btn-sm btn-ghost flex-1 gap-1"
              aria-label="Dark theme"
            >
              <.icon name="hero-moon" class="w-4 h-4" />
              Dark
            </button>
            <button
              type="button"
              onclick="setTheme('system')"
              class="btn btn-sm btn-ghost flex-1 gap-1"
              aria-label="System theme"
            >
              <.icon name="hero-computer-desktop" class="w-4 h-4" />
              Auto
            </button>
          </div>
        </div>

        <%!-- Export button --%>
        <div class="pt-4 border-t border-base-300">
          <button type="button" phx-click="export_data" class="btn btn-sm btn-ghost w-full justify-start gap-2">
            <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
            Export Data
          </button>
        </div>
      </div>
    </aside>
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
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4 shrink-0">
      <h2 class="text-base font-semibold text-base-content"><%= panel_title(@selected_source) %></h2>
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-4">
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
    <form phx-change="filter_events" class="flex flex-wrap items-center gap-2">
      <label for="event-type-filter" class="text-sm text-base-content/70">Type:</label>
      <select id="event-type-filter" name="type" class="select select-sm select-bordered flex-1 min-w-0 sm:flex-none sm:w-auto">
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
      {:get_alerts, "Get Alerts"},
      {:take_snapshot, "Take Snapshot"},
      {:get_snapshot, "Get Snapshot"},
      {:get_snapshots, "Get Snapshots"},
      {:execute_start, "Execute Start"},
      {:execute_complete, "Execute Complete"},
      {:execute_error, "Execute Error"},
      {:wait, "Wait"},
      {:think, "Think"},
      {:llm_error, "LLM Errors"},
      {:alert_received, "Alerts Received"},
      {:update_alert_statuses, "Update Alert Statuses"},
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
    # Get running watchers
    running_watchers =
      case rpc_call(node, Beamlens.Operator.Supervisor, :list_operators, []) do
        {:ok, watchers} -> watchers
        {:error, _reason} -> []
      end

    # Get all configured operator names (builtin + custom)
    configured_operators =
      case rpc_call(node, Beamlens.Operator.Supervisor, :configured_operators, []) do
        {:ok, operators} -> operators
        {:error, _reason} -> []
      end

    # Create a map of running watchers by name
    running_map = Map.new(running_watchers, fn w -> {w.watcher, w} end)

    # Merge: show all configured operators, with running status if available
    configured_operators
    |> Enum.map(fn operator ->
      case Map.get(running_map, operator) do
        nil ->
          # Not running - create a stopped entry
          %{watcher: operator, name: operator, state: :healthy, running: false}

        watcher ->
          watcher
      end
    end)
    |> Enum.sort_by(& &1.watcher)
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
    # Check if the coordinator process exists
    process_running =
      case rpc_call(node, Process, :whereis, [Beamlens.Coordinator]) do
        {:ok, pid} when is_pid(pid) -> true
        _ -> false
      end

    case rpc_call(node, Beamlens.Coordinator, :status, []) do
      {:ok, status} ->
        # Override running to reflect process existence, not loop activity
        Map.put(status, :running, process_running)

      {:error, _reason} ->
        %{running: false, alert_count: 0, unread_count: 0, iteration: 0}
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

  defp format_timestamp_for_file do
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d-%H%M%S")
  end
end

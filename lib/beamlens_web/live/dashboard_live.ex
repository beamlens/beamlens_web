defmodule BeamlensWeb.DashboardLive do
  @moduledoc """
  Main LiveView for the BeamLens dashboard.

  Uses a sidebar + main panel layout:
  - Sidebar: Shows sources (operators, coordinator) and quick filters (notifications, insights)
  - Main panel: Shows events filtered by selection, with cards for notifications/insights views

  Supports cluster-wide monitoring via node selection.
  """

  use BeamlensWeb, :live_view

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.CoordinatorComponents
  import BeamlensWeb.EventComponents
  import BeamlensWeb.Icons
  import BeamlensWeb.SidebarComponents
  import BeamlensWeb.TriggerComponents

  @refresh_interval 5_000
  @rpc_timeout 5_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :net_kernel.monitor_nodes(true, node_type: :all)
      subscribe_to_telemetry()
      schedule_refresh()
    end

    node = Node.self()
    available_skills = load_available_skills(node)
    selected_skill_modules = Enum.map(available_skills, & &1.module)

    {:ok,
     socket
     |> assign(:selected_source, :trigger)
     |> assign(:event_type_filter, nil)
     |> assign(:selected_event_id, nil)
     |> assign(:events_paused, false)
     |> assign(:sidebar_open, false)
     |> assign(:settings_open, false)
     |> assign(:selected_node, node)
     |> assign(:available_nodes, get_nodes())
     |> assign(:trigger_context, "")
     |> assign(:available_skills, available_skills)
     |> assign(:selected_skills, selected_skill_modules)
     |> assign(:analysis_running, false)
     |> assign(:analysis_result, nil)
     |> refresh_data()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    source = parse_source_param(params["source"], socket.assigns.operators)
    type_filter = parse_type_param(params["type"])

    {:noreply,
     socket
     |> assign(:selected_source, source)
     |> assign(:event_type_filter, type_filter)
     |> apply_filters()}
  end

  @impl true
  def handle_event("select_source", %{"source" => source}, socket) do
    source_atom = parse_source_param(source, socket.assigns.operators)

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
    available_skills = load_available_skills(node)
    selected_skill_modules = Enum.map(available_skills, & &1.module)

    {:noreply,
     socket
     |> assign(:selected_node, node)
     |> assign(:available_skills, available_skills)
     |> assign(:selected_skills, selected_skill_modules)
     |> refresh_data()}
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
      notifications: fetch_notifications(node),
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

  def handle_event("copy_to_clipboard", %{"text" => text} = params, socket) do
    copy_id = Map.get(params, "copy-id")
    {:noreply, push_event(socket, "copy", %{text: text, copyId: copy_id})}
  end

  def handle_event("copy_record", %{"data" => data} = params, socket) do
    copy_id = Map.get(params, "copy-id")
    # Format JSON nicely for readability
    formatted =
      data
      |> Jason.decode!()
      |> Jason.encode!(pretty: true)

    {:noreply, push_event(socket, "copy", %{text: formatted, copyId: copy_id})}
  end

  def handle_event("restart_operator", %{"operator" => operator_str}, socket) do
    operator = String.to_existing_atom(operator_str)
    node = socket.assigns.selected_node

    _ = rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [operator])
    result = rpc_call(node, Beamlens.Operator.Supervisor, :start_operator, [operator])

    socket =
      case result do
        {:ok, {:ok, _pid}} ->
          socket
          |> put_flash(:info, "Operator #{operator} restarted successfully")
          |> refresh_data()

        {:ok, {:error, reason}} ->
          put_flash(socket, :error, "Failed to restart #{operator}: #{inspect(reason)}")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error restarting #{operator}: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("stop_operator", %{"operator" => operator_str}, socket) do
    operator = String.to_existing_atom(operator_str)
    node = socket.assigns.selected_node

    result = rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [operator])

    socket =
      case result do
        {:ok, :ok} ->
          socket
          |> put_flash(:info, "Operator #{operator} stopped")
          |> refresh_data()

        {:ok, {:error, :not_found}} ->
          put_flash(socket, :error, "Operator #{operator} not found")

        {:error, reason} ->
          put_flash(socket, :error, "RPC error stopping #{operator}: #{inspect(reason)}")
      end

    {:noreply, socket}
  end

  def handle_event("start_all_operators", _params, socket) do
    node = socket.assigns.selected_node
    operators = socket.assigns.operators

    stopped_operators = Enum.reject(operators, & &1.running)

    results =
      Enum.map(stopped_operators, fn op ->
        {op.operator,
         rpc_call(node, Beamlens.Operator.Supervisor, :start_operator, [op.operator])}
      end)

    {successes, failures} =
      Enum.split_with(results, fn
        {_, {:ok, {:ok, _}}} -> true
        _ -> false
      end)

    socket =
      cond do
        Enum.empty?(stopped_operators) ->
          put_flash(socket, :info, "All operators are already running")

        Enum.empty?(failures) ->
          socket
          |> put_flash(:info, "Started #{length(successes)} operator(s)")
          |> refresh_data()

        true ->
          failed_names = Enum.map(failures, fn {name, _} -> name end) |> Enum.join(", ")

          socket
          |> put_flash(:error, "Failed to start: #{failed_names}")
          |> refresh_data()
      end

    {:noreply, socket}
  end

  def handle_event("stop_all_operators", _params, socket) do
    node = socket.assigns.selected_node
    operators = socket.assigns.operators

    running_operators = Enum.filter(operators, & &1.running)

    results =
      Enum.map(running_operators, fn op ->
        {op.operator, rpc_call(node, Beamlens.Operator.Supervisor, :stop_operator, [op.operator])}
      end)

    {successes, failures} =
      Enum.split_with(results, fn
        {_, {:ok, :ok}} -> true
        _ -> false
      end)

    socket =
      cond do
        Enum.empty?(running_operators) ->
          put_flash(socket, :info, "All operators are already stopped")

        Enum.empty?(failures) ->
          socket
          |> put_flash(:info, "Stopped #{length(successes)} operator(s)")
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

  def handle_event("update_trigger_context", %{"context" => context}, socket) do
    {:noreply, assign(socket, :trigger_context, context)}
  end

  def handle_event("toggle_skill", %{"skill" => skill_str}, socket) do
    skill = String.to_existing_atom(skill_str)
    selected = socket.assigns.selected_skills

    new_selected =
      if skill in selected do
        List.delete(selected, skill)
      else
        [skill | selected]
      end

    {:noreply, assign(socket, :selected_skills, new_selected)}
  end

  def handle_event("select_all_skills", _params, socket) do
    all_skill_modules = Enum.map(socket.assigns.available_skills, & &1.module)
    {:noreply, assign(socket, :selected_skills, all_skill_modules)}
  end

  def handle_event("deselect_all_skills", _params, socket) do
    {:noreply, assign(socket, :selected_skills, [])}
  end

  def handle_event("trigger_analysis", _params, socket) do
    node = socket.assigns.selected_node
    context = %{reason: socket.assigns.trigger_context}
    skills = socket.assigns.selected_skills

    socket =
      socket
      |> assign(:analysis_running, true)
      |> assign(:analysis_result, nil)

    liveview_pid = self()

    Task.start(fn ->
      require Logger

      Logger.info(
        "[Dashboard] Starting analysis task for node=#{node}, skills=#{inspect(skills)}"
      )

      result =
        try do
          opts = [skills: skills, max_iterations: 20]
          res = :erpc.call(node, Beamlens.Coordinator, :run, [context, opts], 300_000)
          Logger.info("[Dashboard] Analysis completed: #{inspect(res, limit: 3)}")
          res
        catch
          :exit, reason ->
            Logger.error("[Dashboard] Analysis failed: #{inspect(reason)}")
            {:error, reason}
        end

      Logger.info("[Dashboard] Sending result to LiveView pid=#{inspect(liveview_pid)}")
      send(liveview_pid, {:analysis_complete, result})
    end)

    {:noreply, socket}
  end

  def handle_event("clear_results", _params, socket) do
    {:noreply, assign(socket, :analysis_result, nil)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, refresh_data(socket)}
  end

  def handle_info({:telemetry_event, _event_name, _data}, socket) do
    {:noreply, refresh_data(socket)}
  end

  def handle_info({:analysis_complete, {:ok, result}}, socket) do
    socket =
      socket
      |> assign(:analysis_running, false)
      |> assign(:analysis_result, result)
      |> put_flash(:info, "Analysis complete")
      |> refresh_data()

    {:noreply, socket}
  end

  def handle_info({:analysis_complete, {:error, reason}}, socket) do
    socket =
      socket
      |> assign(:analysis_running, false)
      |> put_flash(:error, "Analysis failed: #{inspect(reason)}")

    {:noreply, socket}
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
    <div class="flex flex-col h-screen overflow-hidden md:grid md:grid-cols-[260px_1fr] md:grid-rows-[auto_1fr]">
      <header class="md:col-span-2 bg-base-100/95 backdrop-blur-lg border-b border-base-300/50 px-4 py-3 md:px-6 md:py-4 sticky top-0 z-30">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <button
              type="button"
              phx-click="toggle_sidebar"
              class="btn btn-ghost btn-sm btn-square hover:bg-base-200 md:hidden"
              aria-label="Toggle sidebar"
            >
              <.icon name="hero-bars-3" class="w-5 h-5" />
            </button>
            <a href="/dashboard" class="flex items-center gap-2.5 group">
              <img src="/images/logo/icon-blue.png" alt="beamlens" width="32" height="32" class="w-8 h-8 shrink-0 object-contain transition-transform group-hover:scale-105" />
              <h1 class="text-lg md:text-xl font-bold text-base-content">beamlens</h1>
            </a>
          </div>
          <%!-- Desktop header controls --%>
          <div class="hidden md:flex items-center gap-3">
            <div class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-base-200/50">
              <.node_selector
                selected_node={@selected_node}
                available_nodes={@available_nodes}
              />
            </div>
            <div class="hidden lg:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-base-200/30 text-sm text-base-content/60">
              <.icon name="hero-clock" class="w-4 h-4 text-base-content/40" />
              <.timestamp value={@last_updated} />
            </div>
            <div class="flex items-center gap-1 border-l border-base-300/50 pl-3">
              <.timezone_toggle />
              <.theme_toggle />
              <button
                type="button"
                phx-click="export_data"
                class="btn btn-ghost btn-sm gap-2 hover:bg-base-200/50"
              >
                <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                <span class="hidden xl:inline">Export</span>
              </button>
            </div>
          </div>
          <%!-- Mobile settings button --%>
          <button
            type="button"
            phx-click="toggle_settings"
            class="btn btn-ghost btn-sm btn-square hover:bg-base-200 md:hidden"
            aria-label="Open settings"
          >
            <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
          </button>
        </div>
      </header>

      <.source_sidebar
        selected_source={@selected_source}
        analysis_running={@analysis_running}
        notification_count={@notification_counts.total}
        insight_count={length(@insights)}
        mobile_open={@sidebar_open}
      />

      <.settings_panel
        open={@settings_open}
        selected_node={@selected_node}
        available_nodes={@available_nodes}
        last_updated={@last_updated}
      />

      <main class="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8 bg-gradient-to-br from-base-100 to-base-200/30">
        <.main_panel
          selected_source={@selected_source}
          operators={@operators}
          filtered_events={@filtered_events}
          event_type_filter={@event_type_filter}
          event_sources={@event_sources}
          selected_event_id={@selected_event_id}
          events_paused={@events_paused}
          notifications={@notifications}
          insights={@insights}
          coordinator_status={@coordinator_status}
          trigger_context={@trigger_context}
          available_skills={@available_skills}
          selected_skills={@selected_skills}
          analysis_running={@analysis_running}
          analysis_result={@analysis_result}
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
    <div class="flex flex-col gap-4 h-full min-h-0">
      <%= if @selected_source == :trigger do %>
        <div class="shrink-0">
          <.trigger_form
            trigger_context={@trigger_context}
            available_skills={@available_skills}
            selected_skills={@selected_skills}
            analysis_running={@analysis_running}
          />
        </div>

        <div class="flex-1 min-h-0 overflow-y-auto">
          <.analysis_results
            result={@analysis_result}
            analysis_running={@analysis_running}
          />
        </div>
      <% else %>
        <.panel_header
          selected_source={@selected_source}
          operators={@operators}
          event_type_filter={@event_type_filter}
          event_sources={@event_sources}
          events_paused={@events_paused}
        />

        <%= if @selected_source == :coordinator do %>
          <.coordinator_panel status={@coordinator_status} />
        <% end %>

        <.event_list events={@filtered_events} selected_event_id={@selected_event_id} />
      <% end %>
    </div>
    """
  end

  defp panel_header(assigns) do
    assigns =
      assign(assigns, :description, panel_description(assigns.selected_source, assigns.operators))

    ~H"""
    <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 sm:gap-4 shrink-0">
      <div>
        <h2 class="text-base font-semibold text-base-content"><%= panel_title(@selected_source, @operators) %></h2>
        <%= if @description do %>
          <p class="text-sm text-base-content/60 mt-1"><%= @description %></p>
        <% end %>
      </div>
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

  defp type_options(:notifications) do
    [
      {:notification_sent, "Notifications Sent"},
      {:notification_received, "Notifications Received"}
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
      {:notification_sent, "Notifications Sent"},
      {:get_notifications, "Get Notifications"},
      {:take_snapshot, "Take Snapshot"},
      {:get_snapshot, "Get Snapshot"},
      {:get_snapshots, "Get Snapshots"},
      {:execute_start, "Execute Start"},
      {:execute_complete, "Execute Complete"},
      {:execute_error, "Execute Error"},
      {:wait, "Wait"},
      {:think, "Think"},
      {:llm_error, "LLM Errors"},
      {:notification_received, "Notifications Received"},
      {:update_notification_statuses, "Update Notification Statuses"},
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

  defp panel_title(:all, _operators), do: "All Activity"
  defp panel_title(:notifications, _operators), do: "Notifications"
  defp panel_title(:insights, _operators), do: "Insights"
  defp panel_title(:coordinator, _operators), do: "Coordinator"

  defp panel_title(operator, operators) when is_atom(operator) do
    case Enum.find(operators, &(&1.operator == operator)) do
      %{title: title} when is_binary(title) -> "#{title} Activity"
      _ -> "#{operator |> Module.split() |> List.last()} Activity"
    end
  end

  defp panel_description(:all, _operators), do: nil
  defp panel_description(:notifications, _operators), do: nil
  defp panel_description(:insights, _operators), do: nil
  defp panel_description(:coordinator, _operators), do: nil

  defp panel_description(operator, operators) when is_atom(operator) do
    case Enum.find(operators, &(&1.operator == operator)) do
      %{description: description} when is_binary(description) -> description
      _ -> nil
    end
  end

  # URL building and parsing

  defp build_url(source, type_filter) do
    params =
      []
      |> add_param_if_value("source", source_to_string(source))
      |> add_param_if_value("type", type_to_string(type_filter))

    case params do
      [] -> "/dashboard"
      _ -> "/dashboard?" <> URI.encode_query(params)
    end
  end

  defp add_param_if_value(params, _key, nil), do: params
  defp add_param_if_value(params, key, value), do: [{key, value} | params]

  defp source_to_string(:trigger), do: nil
  defp source_to_string(:all), do: "all"
  defp source_to_string(:notifications), do: "notifications"
  defp source_to_string(:insights), do: "insights"
  defp source_to_string(:coordinator), do: "coordinator"
  defp source_to_string(operator) when is_atom(operator), do: Atom.to_string(operator)

  defp type_to_string(nil), do: nil
  defp type_to_string(type) when is_atom(type), do: Atom.to_string(type)

  defp parse_source_param(nil, _operators), do: :trigger
  defp parse_source_param("all", _operators), do: :all
  defp parse_source_param("trigger", _operators), do: :trigger
  defp parse_source_param("notifications", _operators), do: :notifications
  defp parse_source_param("insights", _operators), do: :insights
  defp parse_source_param("coordinator", _operators), do: :coordinator
  defp parse_source_param(source, operators) do
    operator_names = Enum.map(operators, & &1.operator)

    try do
      atom = String.to_existing_atom(source)
      if atom in operator_names, do: atom, else: :all
    rescue
      ArgumentError -> :all
    end
  end

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

  defp filter_by_source(events, :notifications) do
    Enum.filter(events, &(&1.event_type in [:notification_sent, :notification_received]))
  end

  defp filter_by_source(events, :insights) do
    Enum.filter(events, &(&1.event_type == :insight_produced))
  end

  defp filter_by_source(events, operator) when is_atom(operator) do
    Enum.filter(events, &(&1.source == operator))
  end

  defp filter_by_type(events, nil), do: events
  defp filter_by_type(events, type), do: Enum.filter(events, &(&1.event_type == type))

  # Data fetching

  defp refresh_data(socket) do
    node = socket.assigns.selected_node

    operators = fetch_operators(node)
    notifications = fetch_notifications(node)
    notification_counts = fetch_notification_counts(node)
    insights = fetch_insights(node)
    coordinator_status = fetch_coordinator_status(node)

    socket
    |> assign(:operators, operators)
    |> assign(:notifications, notifications)
    |> assign(:notification_counts, notification_counts)
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

  defp fetch_operators(node) do
    case rpc_call(node, Beamlens.Operator.Supervisor, :list_operators, []) do
      {:ok, operators} -> Enum.sort_by(operators, & &1.operator)
      {:error, _reason} -> []
    end
  end

  defp fetch_notifications(node) do
    case rpc_call(node, BeamlensWeb.NotificationStore, :notifications_callback, []) do
      {:ok, notifications} -> notifications
      {:error, _reason} -> []
    end
  end

  defp fetch_notification_counts(node) do
    case rpc_call(node, BeamlensWeb.NotificationStore, :notification_counts_callback, []) do
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

  defp fetch_coordinator_status(_node) do
    # No persistent coordinator - one-shot coordinators are spawned via Coordinator.run/2
    %{running: false, notification_count: 0, unread_count: 0, iteration: 0}
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

  defp load_available_skills(node) do
    case rpc_call(node, Beamlens.Operator.Supervisor, :builtin_skills, []) do
      {:ok, skill_modules} ->
        skill_modules
        |> Enum.map(fn module ->
          %{
            module: module,
            title: safe_call(node, module, :title, format_module_name(module)),
            description: safe_call(node, module, :description, "")
          }
        end)
        |> Enum.sort_by(& &1.title)

      {:error, _} ->
        []
    end
  end

  defp safe_call(node, module, function, default) do
    case rpc_call(node, module, function, []) do
      {:ok, result} -> result
      {:error, _} -> default
    end
  end

  defp format_module_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.upcase()
  end

  defp format_module_name(module), do: to_string(module)

  defp subscribe_to_telemetry do
    pid = self()
    handler_id = "beamlens-dashboard-#{inspect(pid)}"

    events = [
      [:beamlens, :operator, :state_change],
      [:beamlens, :operator, :notification_sent],
      [:beamlens, :coordinator, :insight_produced],
      [:beamlens, :coordinator, :notification_received]
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

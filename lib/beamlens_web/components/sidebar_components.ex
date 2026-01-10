defmodule BeamlensWeb.SidebarComponents do
  @moduledoc """
  Components for the dashboard sidebar navigation.
  """

  use Phoenix.Component

  @doc """
  Renders the main dashboard sidebar with sources and quick filters.
  """
  attr(:selected_source, :any, required: true)
  attr(:watchers, :list, required: true)
  attr(:coordinator_status, :map, required: true)
  attr(:alert_count, :integer, default: 0)
  attr(:insight_count, :integer, default: 0)

  def source_sidebar(assigns) do
    ~H"""
    <aside class="dashboard-sidebar">
      <div class="sidebar-section">
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="all"
          class={["sidebar-item", @selected_source == :all && "selected"]}
        >
          <span class="sidebar-item-icon">○</span>
          <span class="sidebar-item-label">All Sources</span>
        </button>
      </div>

      <div class="sidebar-section">
        <h3 class="sidebar-section-title">Watchers</h3>
        <%= for watcher <- @watchers do %>
          <.watcher_sidebar_item
            watcher={watcher}
            selected={@selected_source == watcher.watcher}
          />
        <% end %>
        <%= if Enum.empty?(@watchers) do %>
          <div class="sidebar-empty">No watchers running</div>
        <% end %>
      </div>

      <div class="sidebar-section">
        <h3 class="sidebar-section-title">Coordinator</h3>
        <.coordinator_sidebar_item
          status={@coordinator_status}
          selected={@selected_source == :coordinator}
        />
      </div>

      <div class="sidebar-section">
        <h3 class="sidebar-section-title">Quick Filters</h3>
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="alerts"
          class={["sidebar-item", @selected_source == :alerts && "selected"]}
        >
          <span class="sidebar-item-icon">🔔</span>
          <span class="sidebar-item-label">Alerts</span>
          <%= if @alert_count > 0 do %>
            <span class="sidebar-item-count"><%= @alert_count %></span>
          <% end %>
        </button>
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="insights"
          class={["sidebar-item", @selected_source == :insights && "selected"]}
        >
          <span class="sidebar-item-icon">💡</span>
          <span class="sidebar-item-label">Insights</span>
          <%= if @insight_count > 0 do %>
            <span class="sidebar-item-count"><%= @insight_count %></span>
          <% end %>
        </button>
      </div>
    </aside>
    """
  end

  @doc """
  Renders a watcher item in the sidebar.
  """
  attr(:watcher, :map, required: true)
  attr(:selected, :boolean, default: false)

  def watcher_sidebar_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_source"
      phx-value-source={@watcher.watcher}
      class={["sidebar-item", @selected && "selected"]}
    >
      <span class={["sidebar-status-dot", "status-#{@watcher.state}"]}></span>
      <span class="sidebar-item-label"><%= format_watcher_name(@watcher.watcher) %></span>
      <span class={["sidebar-state-badge", "badge-#{@watcher.state}"]}>
        <%= @watcher.state %>
      </span>
    </button>
    """
  end

  @doc """
  Renders the coordinator item in the sidebar.
  """
  attr(:status, :map, required: true)
  attr(:selected, :boolean, default: false)

  def coordinator_sidebar_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_source"
      phx-value-source="coordinator"
      class={["sidebar-item coordinator-item", @selected && "selected"]}
    >
      <span class={["sidebar-status-dot", @status.running && "status-running" || "status-stopped"]}></span>
      <span class="sidebar-item-label">Status</span>
      <span class="sidebar-item-meta">
        <%= if @status.running do %>
          running
        <% else %>
          stopped
        <% end %>
      </span>
    </button>
    <div class="coordinator-stats">
      <div class="coordinator-stat">
        <span class="stat-count"><%= @status.alert_count || 0 %></span>
        <span class="stat-label">alerts</span>
      </div>
      <div class="coordinator-stat">
        <span class="stat-count"><%= @status.unread_count || 0 %></span>
        <span class="stat-label">unread</span>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp format_watcher_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.capitalize()
  end

  defp format_watcher_name(name), do: to_string(name)
end

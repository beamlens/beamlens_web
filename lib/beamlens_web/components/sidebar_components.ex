defmodule BeamlensWeb.SidebarComponents do
  @moduledoc """
  Components for the dashboard sidebar navigation.
  """

  use Phoenix.Component

  import BeamlensWeb.Icons

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
    <aside class="bg-base-200 border-r border-base-300 overflow-y-auto py-3">
      <div class="px-2 mb-4">
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="all"
          class={[
            "btn btn-ghost btn-sm justify-start w-full gap-2",
            @selected_source == :all && "btn-active text-primary"
          ]}
        >
          <span class="text-sm w-5 text-center shrink-0">○</span>
          <span class="flex-1 text-left truncate">All Sources</span>
        </button>
      </div>

      <div class="px-2 mb-4">
        <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider px-3 py-2 mb-1">
          Watchers
        </h3>
        <%= for watcher <- @watchers do %>
          <.watcher_sidebar_item
            watcher={watcher}
            selected={@selected_source == watcher.watcher}
          />
        <% end %>
        <%= if Enum.empty?(@watchers) do %>
          <div class="px-3 py-2 text-xs text-base-content/50 italic">No watchers running</div>
        <% end %>
      </div>

      <div class="px-2 mb-4">
        <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider px-3 py-2 mb-1">
          Coordinator
        </h3>
        <.coordinator_sidebar_item
          status={@coordinator_status}
          selected={@selected_source == :coordinator}
        />
      </div>

      <div class="px-2 mb-4">
        <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider px-3 py-2 mb-1">
          Quick Filters
        </h3>
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="alerts"
          class={[
            "btn btn-ghost btn-sm justify-start w-full gap-2",
            @selected_source == :alerts && "btn-active text-primary"
          ]}
        >
          <.icon name="hero-bell" class="w-5 h-5 shrink-0" />
          <span class="flex-1 text-left truncate">Alerts</span>
          <%= if @alert_count > 0 do %>
            <span class="badge badge-sm badge-neutral"><%= @alert_count %></span>
          <% end %>
        </button>
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="insights"
          class={[
            "btn btn-ghost btn-sm justify-start w-full gap-2",
            @selected_source == :insights && "btn-active text-primary"
          ]}
        >
          <.icon name="hero-light-bulb" class="w-5 h-5 shrink-0" />
          <span class="flex-1 text-left truncate">Insights</span>
          <%= if @insight_count > 0 do %>
            <span class="badge badge-sm badge-neutral"><%= @insight_count %></span>
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
      class={[
        "btn btn-ghost btn-sm justify-start w-full gap-2",
        @selected && "btn-active text-primary"
      ]}
    >
      <span class={[
        "w-2 h-2 rounded-full shrink-0",
        status_dot_class(@watcher.state)
      ]}></span>
      <span class="flex-1 text-left truncate"><%= format_watcher_name(@watcher.watcher) %></span>
      <span class={["badge badge-sm", state_badge_class(@watcher.state)]}>
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
      class={[
        "btn btn-ghost btn-sm justify-start w-full gap-2",
        @selected && "btn-active text-primary"
      ]}
    >
      <span class={[
        "w-2 h-2 rounded-full shrink-0",
        if(@status.running, do: "bg-success", else: "bg-error")
      ]}></span>
      <span class="flex-1 text-left truncate">Status</span>
      <span class="text-xs text-base-content/50">
        <%= if @status.running, do: "running", else: "stopped" %>
      </span>
    </button>
    <div class="flex gap-4 px-3 py-1 pl-8">
      <div class="flex items-baseline gap-1">
        <span class="text-sm font-semibold text-base-content"><%= @status.alert_count || 0 %></span>
        <span class="text-xs text-base-content/50">alerts</span>
      </div>
      <div class="flex items-baseline gap-1">
        <span class="text-sm font-semibold text-base-content"><%= @status.unread_count || 0 %></span>
        <span class="text-xs text-base-content/50">unread</span>
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

  defp status_dot_class(:healthy), do: "bg-success"
  defp status_dot_class(:observing), do: "bg-info"
  defp status_dot_class(:warning), do: "bg-warning"
  defp status_dot_class(:critical), do: "bg-error"
  defp status_dot_class(_), do: "bg-neutral"

  defp state_badge_class(:healthy), do: "badge-success"
  defp state_badge_class(:observing), do: "badge-info"
  defp state_badge_class(:warning), do: "badge-warning"
  defp state_badge_class(:critical), do: "badge-error"
  defp state_badge_class(_), do: "badge-neutral"
end

defmodule BeamlensWeb.SidebarComponents do
  @moduledoc """
  Components for the dashboard sidebar navigation.

  Simplified for trigger-based analysis mode.
  """

  use Phoenix.Component

  import BeamlensWeb.Icons

  @doc """
  Renders the main dashboard sidebar with quick filters for trigger mode.
  """
  attr(:selected_source, :any, required: true)
  attr(:analysis_running, :boolean, default: false)
  attr(:notification_count, :integer, default: 0)
  attr(:insight_count, :integer, default: 0)
  attr(:mobile_open, :boolean, default: false)
  attr(:chat_enabled, :boolean, default: false)

  def source_sidebar(assigns) do
    ~H"""
    <div
      class={[
        "fixed inset-0 z-40 md:hidden",
        if(@mobile_open, do: "block", else: "hidden")
      ]}
      phx-click="close_sidebar"
    >
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>
    </div>
    <aside class={[
      "fixed inset-y-0 left-0 z-50 w-72 bg-base-100 border-r border-base-300/50 overflow-y-auto transition-transform duration-300 ease-out md:static md:translate-x-0 md:w-auto shadow-2xl md:shadow-none",
      if(@mobile_open, do: "translate-x-0", else: "-translate-x-full")
    ]}>
      <%!-- Mobile header --%>
      <div class="flex items-center justify-between px-5 py-4 border-b border-base-300/50 md:hidden">
        <span class="text-base font-bold text-base-content">Navigation</span>
        <button
          type="button"
          phx-click="close_sidebar"
          class="btn btn-ghost btn-sm btn-circle hover:bg-base-200"
          aria-label="Close sidebar"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <div class="p-4 space-y-6">
        <%!-- Primary Action Section (only shown when chat is enabled) --%>
        <%= if @chat_enabled do %>
          <div>
            <h2 class="text-[10px] font-bold text-base-content/40 uppercase tracking-[0.15em] px-2 mb-3">
              Actions
            </h2>
            <button
              type="button"
              phx-click="select_source"
              phx-value-source="trigger"
              class={[
                "group relative w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 cursor-pointer",
                if(@selected_source == :trigger,
                  do: "bg-primary text-primary-content shadow-lg shadow-primary/25",
                  else: "bg-base-200/50 text-base-content/80 hover:bg-primary/10 hover:text-primary"
                )
              ]}
            >
              <span class={[
                "w-8 h-8 rounded-lg flex items-center justify-center shrink-0 transition-all duration-200",
                if(@selected_source == :trigger,
                  do: "bg-primary-content/20",
                  else: "bg-primary/10 group-hover:bg-primary/20"
                )
              ]}>
                <%= if @selected_source == :trigger do %>
                  <.icon name="hero-bolt" class="w-4 h-4 text-primary-content" />
                <% else %>
                  <.icon name="hero-bolt" class="w-4 h-4 text-primary" />
                <% end %>
              </span>
              <span class="flex-1 text-left">Trigger</span>
              <%= if @analysis_running do %>
                <span class="loading loading-spinner loading-xs"></span>
              <% end %>
            </button>
          </div>
        <% end %>

        <%!-- Event Filters Section --%>
        <div>
          <h2 class="text-[10px] font-bold text-base-content/40 uppercase tracking-[0.15em] px-2 mb-3">
            Event Filters
          </h2>
          <div class="space-y-1">
            <.sidebar_nav_item
              icon="hero-queue-list"
              label="All Activity"
              source="all"
              selected={@selected_source == :all}
            />
            <.sidebar_nav_item
              icon="hero-bell"
              label="Notifications"
              source="notifications"
              selected={@selected_source == :notifications}
              count={@notification_count}
            />
            <.sidebar_nav_item
              icon="hero-light-bulb"
              label="Insights"
              source="insights"
              selected={@selected_source == :insights}
              count={@insight_count}
            />
            <.sidebar_nav_item
              icon="hero-cpu-chip"
              label="Coordinator"
              source="coordinator"
              selected={@selected_source == :coordinator}
            />
          </div>
        </div>

        <%!-- Status Section --%>
        <div>
          <h2 class="text-[10px] font-bold text-base-content/40 uppercase tracking-[0.15em] px-2 mb-3">
            Status
          </h2>
          <div class="px-3 py-3 rounded-xl bg-base-200/30">
            <div class="flex items-center gap-3">
              <%= if @analysis_running do %>
                <span class="relative flex h-3 w-3">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                  <span class="relative inline-flex rounded-full h-3 w-3 bg-primary"></span>
                </span>
                <span class="text-sm font-medium text-primary">Analysis running...</span>
              <% else %>
                <span class="w-3 h-3 rounded-full bg-base-content/20"></span>
                <span class="text-sm text-base-content/50">Idle</span>
              <% end %>
            </div>
          </div>
        </div>

      </div>
    </aside>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:source, :string, required: true)
  attr(:selected, :boolean, default: false)
  attr(:count, :integer, default: 0)

  defp sidebar_nav_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_source"
      phx-value-source={@source}
      class={[
        "group relative w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all duration-200 cursor-pointer",
        if(@selected,
          do: "bg-primary/10 text-primary font-medium",
          else: "text-base-content/70 hover:bg-base-200/50 hover:text-base-content"
        )
      ]}
    >
      <%!-- Active indicator --%>
      <div class={[
        "absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 rounded-r-full transition-all duration-200",
        if(@selected, do: "bg-primary", else: "bg-transparent")
      ]}></div>

      <%= if @selected do %>
        <.icon name={@icon} class="w-5 h-5 shrink-0 transition-colors text-primary" />
      <% else %>
        <.icon name={@icon} class="w-5 h-5 shrink-0 transition-colors text-base-content/50 group-hover:text-base-content/70" />
      <% end %>
      <span class="flex-1 text-left"><%= @label %></span>
      <%= if @count > 0 do %>
        <span class={[
          "px-2 py-0.5 text-xs font-medium rounded-full tabular-nums",
          if(@selected, do: "bg-primary/20 text-primary", else: "bg-base-300 text-base-content/60")
        ]}>
          <%= @count %>
        </span>
      <% end %>
    </button>
    """
  end
end

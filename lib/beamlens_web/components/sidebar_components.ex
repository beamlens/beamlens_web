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
  attr(:operators, :list, default: [])
  attr(:coordinator_status, :map, default: %{running: false})
  attr(:selected_operator, :atom, default: nil)

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

        <%!-- Filters Section --%>
        <div>
          <h2 class="text-[10px] font-bold text-base-content/40 uppercase tracking-[0.15em] px-2 mb-3">
            Filters
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
            <%!-- Coordinator --%>
            <.process_item
              name="Coordinator"
              icon="hero-cpu-chip"
              running={@coordinator_status.running || @analysis_running}
              selected={@selected_source == :coordinator}
              click_event="select_source"
              click_value="coordinator"
            />
          </div>
          <%!-- Operators subsection (grouped in a card) --%>
          <%= if @operators != [] do %>
            <div class="mt-3 rounded-lg border border-base-300/50 bg-base-200/30 p-2">
              <div class="text-[10px] font-bold text-base-content/40 uppercase tracking-[0.15em] px-1 mb-2">
                Operators
              </div>
              <div class="space-y-0.5">
                <%= for operator <- @operators do %>
                  <.operator_item
                    operator={operator}
                    selected={@selected_operator == operator.operator}
                  />
                <% end %>
              </div>
            </div>
          <% end %>
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

  attr(:name, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:running, :boolean, default: false)
  attr(:selected, :boolean, default: false)
  attr(:click_event, :string, required: true)
  attr(:click_value, :string, required: true)

  defp process_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={@click_event}
      phx-value-source={@click_value}
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
      <span class="flex-1 text-left"><%= @name %></span>

      <%!-- Status indicator - only show spinner when running --%>
      <%= if @running do %>
        <span class="flex items-center gap-1.5 text-success">
          <span class="loading loading-spinner loading-xs"></span>
        </span>
      <% end %>
    </button>
    """
  end

  attr(:operator, :map, required: true)
  attr(:selected, :boolean, default: false)

  defp operator_item(assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <%= if @selected do %>
        <button
          type="button"
          phx-click="clear_operator_filter"
          class="p-1 rounded hover:bg-base-300/50 text-base-content/50 hover:text-base-content transition-colors cursor-pointer"
          title="Clear filter"
        >
          <.icon name="hero-x-mark" class="w-3 h-3" />
        </button>
      <% else %>
        <div class="w-5"></div>
      <% end %>
      <button
        type="button"
        phx-click="select_operator"
        phx-value-operator={@operator.operator}
        class={[
          "group relative flex-1 flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all duration-200 cursor-pointer",
          if(@selected,
            do: "bg-primary/10 text-primary font-medium",
            else: "text-base-content/60 hover:bg-base-200/50 hover:text-base-content"
          )
        ]}
        title={@operator.title}
      >
        <span class="flex-1 text-left text-xs"><%= format_operator_name(@operator.operator) %></span>

        <%= if @operator.running do %>
          <span class="flex items-center gap-1.5 text-success">
            <span class="loading loading-spinner loading-xs"></span>
          </span>
        <% end %>
      </button>
    </div>
    """
  end

  defp format_operator_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp format_operator_name(name), do: to_string(name)
end

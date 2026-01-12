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
  attr(:operators, :list, required: true)
  attr(:coordinator_status, :map, required: true)
  attr(:notification_count, :integer, default: 0)
  attr(:insight_count, :integer, default: 0)
  attr(:mobile_open, :boolean, default: false)

  def source_sidebar(assigns) do
    ~H"""
    <div
      class={[
        "fixed inset-0 z-40 md:hidden",
        if(@mobile_open, do: "block", else: "hidden")
      ]}
      phx-click="close_sidebar"
    >
      <div class="absolute inset-0 bg-black/50"></div>
    </div>
    <aside class={[
      "fixed inset-y-0 left-0 z-50 w-64 bg-base-200 border-r border-base-300 overflow-y-auto py-3 transition-transform duration-200 ease-in-out md:static md:translate-x-0 md:w-auto",
      if(@mobile_open, do: "translate-x-0", else: "-translate-x-full")
    ]}>
      <div class="flex items-center justify-between px-4 py-2 mb-2 md:hidden">
        <span class="text-sm font-semibold text-base-content">Navigation</span>
        <button
          type="button"
          phx-click="close_sidebar"
          class="btn btn-ghost btn-sm btn-square"
          aria-label="Close sidebar"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>
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
          <span class="flex-1 text-left truncate">All Activity</span>
        </button>
      </div>

      <div class="px-2 mb-4">
        <div class="flex items-center justify-between px-3 py-2 mb-1">
          <h2 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">
            Operators
          </h2>
          <.all_operators_controls operators={@operators} />
        </div>
        <%= for operator <- @operators do %>
          <.operator_sidebar_item
            operator={operator}
            selected={@selected_source == operator.operator}
          />
        <% end %>
        <%= if Enum.empty?(@operators) do %>
          <div class="px-3 py-2 text-xs text-base-content/50 italic">No operators running</div>
        <% end %>
      </div>

      <div class="px-2 mb-4">
        <h2 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider px-3 py-2 mb-1">
          Coordinator
        </h2>
        <.coordinator_sidebar_item
          status={@coordinator_status}
          selected={@selected_source == :coordinator}
        />
      </div>

      <div class="px-2 mb-4">
        <h2 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider px-3 py-2 mb-1">
          Quick Filters
        </h2>
        <button
          type="button"
          phx-click="select_source"
          phx-value-source="notifications"
          class={[
            "btn btn-ghost btn-sm justify-start w-full gap-2",
            @selected_source == :notifications && "btn-active text-primary"
          ]}
        >
          <.icon name="hero-bell" class="w-5 h-5 shrink-0" />
          <span class="flex-1 text-left truncate">Notifications</span>
          <%= if @notification_count > 0 do %>
            <span class="badge badge-sm badge-neutral"><%= @notification_count %></span>
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
  Renders an operator item in the sidebar.
  """
  attr(:operator, :map, required: true)
  attr(:selected, :boolean, default: false)

  def operator_sidebar_item(assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <button
        type="button"
        phx-click={if @operator.running, do: "stop_operator", else: "restart_operator"}
        phx-value-operator={@operator.operator}
        class={[
          "btn btn-ghost btn-xs btn-square",
          if(@operator.running, do: "text-success hover:text-success", else: "text-error hover:text-error")
        ]}
        title={if @operator.running, do: "Click to stop #{format_operator_name(@operator.operator)}", else: "Click to start #{format_operator_name(@operator.operator)}"}
      >
        <%= if @operator.running do %>
          <.icon name="hero-stop-circle" class="w-4 h-4" />
        <% else %>
          <.icon name="hero-play-circle" class="w-4 h-4" />
        <% end %>
      </button>
      <button
        type="button"
        phx-click="select_source"
        phx-value-source={@operator.operator}
        class={[
          "btn btn-ghost btn-sm justify-start flex-1 gap-2",
          @selected && "btn-active text-primary"
        ]}
      >
        <span class="flex-1 text-left truncate"><%= format_operator_name(@operator.operator) %></span>
      </button>
    </div>
    """
  end

  @doc """
  Renders the coordinator item in the sidebar.
  """
  attr(:status, :map, required: true)
  attr(:selected, :boolean, default: false)

  def coordinator_sidebar_item(assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <button
        type="button"
        phx-click={if @status.running, do: "stop_coordinator", else: "start_coordinator"}
        class={[
          "btn btn-ghost btn-xs btn-square",
          if(@status.running, do: "text-success hover:text-success", else: "text-error hover:text-error")
        ]}
        title={if @status.running, do: "Click to stop coordinator", else: "Click to start coordinator"}
      >
        <%= if @status.running do %>
          <.icon name="hero-stop-circle" class="w-4 h-4" />
        <% else %>
          <.icon name="hero-play-circle" class="w-4 h-4" />
        <% end %>
      </button>
      <button
        type="button"
        phx-click="select_source"
        phx-value-source="coordinator"
        class={[
          "btn btn-ghost btn-sm justify-start flex-1 gap-2",
          @selected && "btn-active text-primary"
        ]}
      >
        <span class="flex-1 text-left truncate">Status</span>
      </button>
    </div>
    <div class="flex gap-4 px-3 py-1 pl-8">
      <div class="flex items-baseline gap-1">
        <span class="text-sm font-semibold text-base-content"><%= @status.notification_count || 0 %></span>
        <span class="text-xs text-base-content/50">notifications</span>
      </div>
      <div class="flex items-baseline gap-1">
        <span class="text-sm font-semibold text-base-content"><%= @status.unread_count || 0 %></span>
        <span class="text-xs text-base-content/50">unread</span>
      </div>
    </div>
    """
  end

  @doc """
  Renders start/stop all controls for operators.
  """
  attr(:operators, :list, required: true)

  def all_operators_controls(assigns) do
    all_running = Enum.all?(assigns.operators, & &1.running)
    any_running = Enum.any?(assigns.operators, & &1.running)
    assigns = assign(assigns, all_running: all_running, any_running: any_running)

    ~H"""
    <%= cond do %>
      <% @all_running -> %>
        <button
          type="button"
          phx-click="stop_all_operators"
          class="btn btn-ghost btn-xs btn-square text-success hover:text-success"
          title="Click to stop all operators"
        >
          <.icon name="hero-stop-circle" class="w-4 h-4" />
        </button>
      <% @any_running -> %>
        <div class="flex">
          <button
            type="button"
            phx-click="start_all_operators"
            class="btn btn-ghost btn-xs btn-square text-error hover:text-error"
            title="Click to start all operators"
          >
            <.icon name="hero-play-circle" class="w-4 h-4" />
          </button>
          <button
            type="button"
            phx-click="stop_all_operators"
            class="btn btn-ghost btn-xs btn-square text-success hover:text-success"
            title="Click to stop all operators"
          >
            <.icon name="hero-stop-circle" class="w-4 h-4" />
          </button>
        </div>
      <% true -> %>
        <button
          type="button"
          phx-click="start_all_operators"
          class="btn btn-ghost btn-xs btn-square text-error hover:text-error"
          title="Click to start all operators"
        >
          <.icon name="hero-play-circle" class="w-4 h-4" />
        </button>
    <% end %>
    """
  end

  defp format_operator_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.capitalize()
  end

  defp format_operator_name(name), do: to_string(name)
end

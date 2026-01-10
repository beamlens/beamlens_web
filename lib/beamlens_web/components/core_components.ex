defmodule BeamlensWeb.CoreComponents do
  @moduledoc """
  Shared UI components for the BeamLens dashboard.
  """

  use Phoenix.Component

  @doc """
  Renders a badge with the given variant.
  """
  attr(:variant, :atom, required: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["badge", "badge-#{@variant}", @class]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc """
  Renders a status indicator dot.
  """
  attr(:running, :boolean, required: true)

  def status_dot(assigns) do
    ~H"""
    <span class={["status-dot", if(@running, do: "running", else: "stopped")]}></span>
    """
  end

  @doc """
  Renders a card container.
  """
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders an empty state message.
  """
  attr(:icon, :string, default: "📭")
  attr(:message, :string, required: true)

  def empty_state(assigns) do
    ~H"""
    <div class="empty-state">
      <div class="empty-state-icon"><%= @icon %></div>
      <p><%= @message %></p>
    </div>
    """
  end

  @doc """
  Formats a DateTime for display.
  """
  def format_datetime(nil), do: "-"

  def format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  def format_datetime(other), do: inspect(other)

  @doc """
  Formats a relative time (e.g., "2 minutes ago").
  """
  def format_relative(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, dt, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  def format_relative(_), do: "-"

  @doc """
  Renders a node selector dropdown for cluster-wide monitoring.
  """
  attr(:selected_node, :atom, required: true)
  attr(:available_nodes, :list, required: true)

  def node_selector(assigns) do
    ~H"""
    <form phx-change="select_node" class="node-selector">
      <label for="node-select">Node:</label>
      <select id="node-select" name="node">
        <%= for node <- @available_nodes do %>
          <option value={node} selected={@selected_node == node}>
            <%= format_node_name(node) %>
          </option>
        <% end %>
      </select>
    </form>
    """
  end

  @doc """
  Renders a node badge showing which node data came from.
  """
  attr(:node, :atom, required: true)

  def node_badge(assigns) do
    ~H"""
    <span class="node-badge" title={to_string(@node)}>
      <%= format_node_name(@node) %>
    </span>
    """
  end

  @doc """
  Formats a node name for display.
  Extracts the hostname from node@host format.
  """
  def format_node_name(node) when is_atom(node) do
    node
    |> Atom.to_string()
    |> String.split("@")
    |> case do
      [name, _host] -> name
      [name] -> name
    end
  end

  def format_node_name(node), do: to_string(node)
end

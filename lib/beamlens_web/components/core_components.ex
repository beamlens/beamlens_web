defmodule BeamlensWeb.CoreComponents do
  @moduledoc """
  Shared UI components for the BeamLens dashboard.
  """

  use Phoenix.Component

  import BeamlensWeb.Icons

  @doc """
  Renders a badge with the given variant.

  Variants are mapped to DaisyUI badge classes:
  - States: `:healthy`, `:observing`, `:warning`, `:critical`, `:idle`
  - Severities: `:info`, `:warning`, `:critical`
  - Alert statuses: `:unread`, `:acknowledged`, `:resolved`
  - Confidence: `:high`, `:medium`, `:low`
  - Correlation types: `:temporal`, `:causal`, `:pattern`
  """
  attr(:variant, :atom, required: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["badge badge-sm", variant_class(@variant), @class]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  # Maps semantic variants to DaisyUI badge classes
  defp variant_class(:healthy), do: "badge-success"
  defp variant_class(:observing), do: "badge-info"
  defp variant_class(:warning), do: "badge-warning"
  defp variant_class(:critical), do: "badge-error"
  defp variant_class(:idle), do: "badge-neutral"
  # Alert severities
  defp variant_class(:info), do: "badge-info"
  # Alert statuses
  defp variant_class(:unread), do: "badge-warning"
  defp variant_class(:acknowledged), do: "badge-info"
  defp variant_class(:resolved), do: "badge-success"
  # Insight confidence
  defp variant_class(:high), do: "badge-success"
  defp variant_class(:medium), do: "badge-warning"
  defp variant_class(:low), do: "badge-neutral"
  # Insight correlation types
  defp variant_class(:temporal), do: "badge-info"
  defp variant_class(:causal), do: "badge-primary"
  defp variant_class(:pattern), do: "badge-secondary"
  defp variant_class(:common_cause), do: "badge-accent"
  # Fallback
  defp variant_class(_), do: "badge-neutral"

  @doc """
  Renders a status indicator dot.
  """
  attr(:running, :boolean, required: true)

  def status_dot(assigns) do
    ~H"""
    <span class={[
      "w-2 h-2 rounded-full inline-block",
      if(@running, do: "bg-success", else: "bg-error")
    ]}></span>
    """
  end

  @doc """
  Renders a card container.
  """
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-200 border border-base-300 rounded-lg overflow-hidden", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders an empty state message.
  """
  attr(:icon, :string, default: "hero-inbox")
  attr(:message, :string, required: true)

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-12 px-4 text-base-content/50">
      <.icon name={@icon} class="w-12 h-12 mx-auto mb-3 opacity-50" />
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
    <form phx-change="select_node" class="flex items-center gap-2">
      <label for="node-select" class="text-sm text-base-content/70">Node:</label>
      <select id="node-select" name="node" class="select select-sm select-bordered">
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
    <span class="badge badge-sm badge-ghost font-mono" title={to_string(@node)}>
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

  @doc """
  Renders a theme toggle dropdown for switching between light, dark, and system modes.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
        <.icon name="hero-sun" class="w-5 h-5 theme-icon-light" />
        <.icon name="hero-moon" class="w-5 h-5 theme-icon-dark" />
        <.icon name="hero-computer-desktop" class="w-5 h-5 theme-icon-system" />
      </div>
      <ul tabindex="0" class="dropdown-content z-50 menu p-2 shadow-lg bg-base-200 rounded-box w-36">
        <li>
          <a onclick="setTheme('light')" class="flex gap-2">
            <.icon name="hero-sun" class="w-4 h-4" />
            Light
          </a>
        </li>
        <li>
          <a onclick="setTheme('dark')" class="flex gap-2">
            <.icon name="hero-moon" class="w-4 h-4" />
            Dark
          </a>
        </li>
        <li>
          <a onclick="setTheme('system')" class="flex gap-2">
            <.icon name="hero-computer-desktop" class="w-4 h-4" />
            System
          </a>
        </li>
      </ul>
    </div>
    """
  end
end

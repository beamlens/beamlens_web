defmodule BeamlensWeb.AlertComponents do
  @moduledoc """
  Components for displaying alerts.
  """

  use Phoenix.Component
  import BeamlensWeb.CoreComponents

  @doc """
  Renders an alert card.
  """
  attr(:alert, :map, required: true)

  def alert_card(assigns) do
    ~H"""
    <.card class="mb-4">
      <div class="p-4 border-b border-base-300 flex items-center gap-3">
        <.badge variant={@alert.severity}><%= @alert.severity %></.badge>
        <.badge variant={@alert.status}><%= @alert.status %></.badge>
        <span class="font-medium text-base-content"><%= format_watcher_name(@alert.watcher) %></span>
      </div>
      <div class="p-4">
        <p class="text-base mb-3"><%= @alert.summary %></p>
        <div class="flex flex-wrap gap-3 text-sm text-base-content/70">
          <span>Type: <%= @alert.anomaly_type %></span>
          <span class="font-mono text-xs"><%= format_datetime(@alert.detected_at) %></span>
        </div>
      </div>
    </.card>
    """
  end

  @doc """
  Renders filter pills for alert status.
  """
  attr(:current_filter, :atom, default: nil)
  attr(:counts, :map, required: true)

  def alert_filters(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 mb-4">
      <button
        phx-click="filter_alerts"
        phx-value-status=""
        class={[
          "btn btn-sm",
          if(@current_filter == nil, do: "btn-primary", else: "btn-ghost")
        ]}
      >
        All (<%= @counts.total %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="unread"
        class={[
          "btn btn-sm",
          if(@current_filter == :unread, do: "btn-warning", else: "btn-ghost")
        ]}
      >
        Unread (<%= @counts.unread %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="acknowledged"
        class={[
          "btn btn-sm",
          if(@current_filter == :acknowledged, do: "btn-info", else: "btn-ghost")
        ]}
      >
        Acknowledged (<%= @counts.acknowledged %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="resolved"
        class={[
          "btn btn-sm",
          if(@current_filter == :resolved, do: "btn-success", else: "btn-ghost")
        ]}
      >
        Resolved (<%= @counts.resolved %>)
      </button>
    </div>
    """
  end

  @doc """
  Renders a list of alert cards.
  """
  attr(:alerts, :list, required: true)

  def alert_list(assigns) do
    ~H"""
    <div>
      <%= for alert <- @alerts do %>
        <.alert_card alert={alert} />
      <% end %>
    </div>
    """
  end

  defp format_watcher_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_watcher_name(name), do: to_string(name)
end

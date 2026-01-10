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
    <.card>
      <div class="card-header">
        <.badge variant={@alert.severity}><%= @alert.severity %></.badge>
        <.badge variant={@alert.status}><%= @alert.status %></.badge>
        <span class="watcher-name"><%= format_watcher_name(@alert.watcher) %></span>
      </div>
      <div class="card-body">
        <p class="alert-summary"><%= @alert.summary %></p>
        <div class="alert-meta">
          <span>Type: <%= @alert.anomaly_type %></span>
          <span class="timestamp"><%= format_datetime(@alert.detected_at) %></span>
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
    <div class="filter-pills">
      <button
        phx-click="filter_alerts"
        phx-value-status=""
        class={["filter-pill", @current_filter == nil && "active"]}
      >
        All (<%= @counts.total %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="unread"
        class={["filter-pill", @current_filter == :unread && "active"]}
      >
        Unread (<%= @counts.unread %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="acknowledged"
        class={["filter-pill", @current_filter == :acknowledged && "active"]}
      >
        Acknowledged (<%= @counts.acknowledged %>)
      </button>
      <button
        phx-click="filter_alerts"
        phx-value-status="resolved"
        class={["filter-pill", @current_filter == :resolved && "active"]}
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

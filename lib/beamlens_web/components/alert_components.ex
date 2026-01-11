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
    <.card class="mb-4 relative">
      <div class="absolute top-2 right-2">
        <.copy_all_button data={Map.from_struct(@alert)} />
      </div>
      <div class="p-4 border-b border-base-300 flex items-center gap-3 pr-10">
        <.badge variant={@alert.severity}><%= @alert.severity %></.badge>
        <.badge variant={@alert.status}><%= @alert.status %></.badge>
        <span class="font-medium text-base-content"><%= format_operator_name(@alert.operator) %></span>
        <span class="flex-1"></span>
        <.copyable value={@alert.id} display={String.slice(@alert.id, 0..7) <> "..."} code={true} />
      </div>
      <div class="p-4">
        <p class="text-base mb-3">
          <.copyable value={@alert.summary} code={false} class="text-base-content" />
        </p>
        <div class="flex flex-wrap gap-3 text-sm text-base-content/70">
          <span>Type: <.copyable value={to_string(@alert.anomaly_type)} code={false} class="text-base-content/70" /></span>
          <span class="font-mono text-xs"><.timestamp value={@alert.detected_at} format={:datetime} /></span>
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

  defp format_operator_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_operator_name(name), do: to_string(name)
end

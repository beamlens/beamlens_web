defmodule BeamlensWeb.NotificationComponents do
  @moduledoc """
  Components for displaying notifications.
  """

  use Phoenix.Component
  import BeamlensWeb.CoreComponents

  @doc """
  Renders a notification card.
  """
  attr(:notification, :map, required: true)

  def notification_card(assigns) do
    ~H"""
    <.card class="mb-4 relative">
      <div class="absolute top-2 right-2">
        <.copy_all_button data={Map.from_struct(@notification)} />
      </div>
      <div class="p-4 border-b border-base-300 flex items-center gap-3 pr-10">
        <.badge variant={@notification.severity}><%= @notification.severity %></.badge>
        <.badge variant={@notification.status}><%= @notification.status %></.badge>
        <span class="font-medium text-base-content"><%= format_operator_name(@notification.operator) %></span>
        <span class="flex-1"></span>
        <.copyable value={@notification.id} display={String.slice(@notification.id, 0..7) <> "..."} code={true} />
      </div>
      <div class="p-4 space-y-3">
        <div>
          <span class="text-xs font-medium text-base-content/50 uppercase tracking-wide">Observation</span>
          <p class="text-base">
            <.copyable value={@notification.observation} code={false} class="text-base-content" />
          </p>
        </div>
        <%= if @notification.context do %>
          <div>
            <span class="text-xs font-medium text-base-content/50 uppercase tracking-wide">Context</span>
            <p class="text-sm text-base-content/70">
              <.copyable value={@notification.context} code={false} class="text-base-content/70" />
            </p>
          </div>
        <% end %>
        <%= if @notification.hypothesis do %>
          <div>
            <span class="text-xs font-medium text-base-content/50 uppercase tracking-wide">Hypothesis</span>
            <p class="text-sm text-base-content/70 italic">
              <.copyable value={@notification.hypothesis} code={false} class="text-base-content/70" />
            </p>
          </div>
        <% end %>
        <div class="flex flex-wrap gap-3 text-sm text-base-content/70 pt-2 border-t border-base-300">
          <span>Type: <.copyable value={to_string(@notification.anomaly_type)} code={false} class="text-base-content/70" /></span>
          <span class="font-mono text-xs"><.timestamp value={@notification.detected_at} format={:datetime} /></span>
        </div>
      </div>
    </.card>
    """
  end

  @doc """
  Renders filter pills for notification status.
  """
  attr(:current_filter, :atom, default: nil)
  attr(:counts, :map, required: true)

  def notification_filters(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 mb-4">
      <button
        phx-click="filter_notifications"
        phx-value-status=""
        class={[
          "btn btn-sm",
          if(@current_filter == nil, do: "btn-primary", else: "btn-ghost")
        ]}
      >
        All (<%= @counts.total %>)
      </button>
      <button
        phx-click="filter_notifications"
        phx-value-status="unread"
        class={[
          "btn btn-sm",
          if(@current_filter == :unread, do: "btn-warning", else: "btn-ghost")
        ]}
      >
        Unread (<%= @counts.unread %>)
      </button>
      <button
        phx-click="filter_notifications"
        phx-value-status="acknowledged"
        class={[
          "btn btn-sm",
          if(@current_filter == :acknowledged, do: "btn-info", else: "btn-ghost")
        ]}
      >
        Acknowledged (<%= @counts.acknowledged %>)
      </button>
      <button
        phx-click="filter_notifications"
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
  Renders a list of notification cards.
  """
  attr(:notifications, :list, required: true)

  def notification_list(assigns) do
    ~H"""
    <div>
      <%= for notification <- @notifications do %>
        <.notification_card notification={notification} />
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

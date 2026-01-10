defmodule BeamlensWeb.CoordinatorComponents do
  @moduledoc """
  Components for displaying coordinator status and insights.
  """

  use Phoenix.Component
  import BeamlensWeb.CoreComponents

  @doc """
  Renders the coordinator status cards.
  """
  attr(:status, :map, required: true)

  def coordinator_status(assigns) do
    ~H"""
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
      <div class="bg-base-200 border border-base-300 rounded-lg p-4">
        <div class="text-xs text-base-content/50 uppercase tracking-wider mb-1">Status</div>
        <div class={[
          "text-2xl font-semibold",
          if(@status.running, do: "text-success", else: "text-base-content/50")
        ]}>
          <%= if @status.running, do: "Running", else: "Idle" %>
        </div>
      </div>
      <div class="bg-base-200 border border-base-300 rounded-lg p-4">
        <div class="text-xs text-base-content/50 uppercase tracking-wider mb-1">Iteration</div>
        <div class="text-2xl font-semibold text-base-content"><%= @status.iteration %></div>
      </div>
      <div class="bg-base-200 border border-base-300 rounded-lg p-4">
        <div class="text-xs text-base-content/50 uppercase tracking-wider mb-1">Total Alerts</div>
        <div class="text-2xl font-semibold text-base-content"><%= @status.alert_count %></div>
      </div>
      <div class="bg-base-200 border border-base-300 rounded-lg p-4">
        <div class="text-xs text-base-content/50 uppercase tracking-wider mb-1">Unread Alerts</div>
        <div class={[
          "text-2xl font-semibold",
          if(@status.unread_count > 0, do: "text-primary", else: "text-base-content")
        ]}>
          <%= @status.unread_count %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders an insight card.
  """
  attr(:insight, :map, required: true)

  def insight_card(assigns) do
    ~H"""
    <.card class="mb-4">
      <div class="p-4 border-b border-base-300 flex items-center gap-3">
        <.badge variant={@insight.correlation_type}><%= @insight.correlation_type %></.badge>
        <.badge variant={@insight.confidence}>Confidence: <%= @insight.confidence %></.badge>
      </div>
      <div class="p-4">
        <p class="text-base mb-3"><%= @insight.summary %></p>
        <%= if @insight.root_cause_hypothesis do %>
          <div class="bg-base-100 p-3 rounded text-sm text-base-content/70 mb-3">
            <strong>Root Cause Hypothesis:</strong> <%= @insight.root_cause_hypothesis %>
          </div>
        <% end %>
        <div class="flex flex-wrap gap-3 text-sm text-base-content/70">
          <span>Correlated <%= length(@insight.alert_ids) %> alert(s)</span>
          <span class="font-mono text-xs"><%= format_datetime(@insight.created_at) %></span>
        </div>
      </div>
    </.card>
    """
  end

  @doc """
  Renders a list of insight cards.
  """
  attr(:insights, :list, required: true)

  def insight_list(assigns) do
    ~H"""
    <div>
      <%= for insight <- @insights do %>
        <.insight_card insight={insight} />
      <% end %>
    </div>
    """
  end
end

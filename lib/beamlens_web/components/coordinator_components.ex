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
    <div class="coordinator-status">
      <div class="stat-card">
        <div class="stat-label">Status</div>
        <div class="stat-value" style={"color: #{if @status.running, do: "var(--success)", else: "var(--text-muted)"}"}>
          <%= if @status.running, do: "Running", else: "Idle" %>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Iteration</div>
        <div class="stat-value"><%= @status.iteration %></div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Total Alerts</div>
        <div class="stat-value"><%= @status.alert_count %></div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Unread Alerts</div>
        <div class="stat-value" style={"color: #{if @status.unread_count > 0, do: "var(--brand-orange)", else: "inherit"}"}>
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
    <.card>
      <div class="card-header">
        <.badge variant={@insight.correlation_type}><%= @insight.correlation_type %></.badge>
        <.badge variant={@insight.confidence}>Confidence: <%= @insight.confidence %></.badge>
      </div>
      <div class="card-body">
        <p class="insight-summary"><%= @insight.summary %></p>
        <%= if @insight.root_cause_hypothesis do %>
          <div class="insight-hypothesis">
            <strong>Root Cause Hypothesis:</strong> <%= @insight.root_cause_hypothesis %>
          </div>
        <% end %>
        <div class="insight-meta">
          <span>Correlated <%= length(@insight.alert_ids) %> alert(s)</span>
          <span class="timestamp"><%= format_datetime(@insight.created_at) %></span>
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

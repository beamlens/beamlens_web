defmodule BeamlensWeb.OperatorComponents do
  @moduledoc """
  Components for displaying operator information.
  """

  use Phoenix.Component
  import BeamlensWeb.CoreComponents

  @doc """
  Renders an operator card showing name, state, and running status.
  """
  attr(:operator, :map, required: true)

  def operator_card(assigns) do
    ~H"""
    <.card class="mb-4">
      <div class="p-4 flex items-center gap-3">
        <.badge variant={@operator.state}><%= @operator.state %></.badge>
        <span class="font-medium text-base-content flex-1"><%= format_operator_name(@operator.operator) %></span>
        <div class="flex items-center gap-2 text-sm text-base-content/70">
          <.status_dot running={@operator.running} />
          <span><%= if @operator.running, do: "Running", else: "Stopped" %></span>
        </div>
      </div>
    </.card>
    """
  end

  @doc """
  Renders a grid of operator cards.
  """
  attr(:operators, :list, required: true)

  def operator_list(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= for operator <- @operators do %>
        <.operator_card operator={operator} />
      <% end %>
    </div>
    """
  end

  defp format_operator_name(name) when is_atom(name) do

    name
    |> Module.split()
    |> List.last()
  end

  defp format_operator_name(name), do: to_string(name)
end

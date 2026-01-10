defmodule BeamlensWeb.WatcherComponents do
  @moduledoc """
  Components for displaying watcher information.
  """

  use Phoenix.Component
  import BeamlensWeb.CoreComponents

  @doc """
  Renders a watcher card showing name, state, and running status.
  """
  attr(:watcher, :map, required: true)

  def watcher_card(assigns) do
    ~H"""
    <.card>
      <div class="card-header">
        <.badge variant={@watcher.state}><%= @watcher.state %></.badge>
        <span class="watcher-name"><%= format_watcher_name(@watcher.watcher) %></span>
        <div class="watcher-running">
          <.status_dot running={@watcher.running} />
          <%= if @watcher.running, do: "Running", else: "Stopped" %>
        </div>
      </div>
    </.card>
    """
  end

  @doc """
  Renders a grid of watcher cards.
  """
  attr(:watchers, :list, required: true)

  def watcher_list(assigns) do
    ~H"""
    <div class="watcher-grid">
      <%= for watcher <- @watchers do %>
        <.watcher_card watcher={watcher} />
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

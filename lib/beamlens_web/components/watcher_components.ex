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
    <.card class="mb-4">
      <div class="p-4 flex items-center gap-3">
        <.badge variant={@watcher.state}><%= @watcher.state %></.badge>
        <span class="font-medium text-base-content flex-1"><%= format_watcher_name(@watcher.watcher) %></span>
        <div class="flex items-center gap-2 text-sm text-base-content/70">
          <.status_dot running={@watcher.running} />
          <span><%= if @watcher.running, do: "Running", else: "Stopped" %></span>
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
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
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

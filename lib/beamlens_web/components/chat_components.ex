defmodule BeamlensWeb.ChatComponents do
  @moduledoc """
  Chat interface components for the BeamLens dashboard.
  Provides a ChatGPT-style conversation UI using DaisyUI chat components.
  """

  use Phoenix.Component

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.Icons

  @doc """
  Main chat container with messages area and input.
  """
  attr :messages, :list, required: true
  attr :input_text, :string, required: true
  attr :analysis_running, :boolean, default: false

  def chat_container(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <div
        id="chat-messages"
        phx-hook=".ChatScroll"
        class="flex-1 min-h-0 overflow-y-auto p-4 space-y-4"
      >
        <.messages_area messages={@messages} analysis_running={@analysis_running} />
      </div>

      <div class="shrink-0 border-t border-base-300 bg-base-100">
        <.chat_input
          input_text={@input_text}
          analysis_running={@analysis_running}
        />
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChatScroll" runtime>
      {
        mounted() {
          this.scrollToBottom()
          this.observer = new MutationObserver(() => this.scrollToBottom())
          this.observer.observe(this.el, { childList: true, subtree: true })
        },
        updated() {
          this.scrollToBottom()
        },
        destroyed() {
          if (this.observer) this.observer.disconnect()
        },
        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight
        }
      }
    </script>
    """
  end

  @doc """
  Renders the scrollable messages area.
  """
  attr :messages, :list, required: true
  attr :analysis_running, :boolean, default: false

  def messages_area(assigns) do
    ~H"""
    <%= if Enum.empty?(@messages) do %>
      <.empty_chat_state />
    <% else %>
      <%= for message <- @messages do %>
        <%= case message.role do %>
          <% :user -> %>
            <.user_message message={message} />
          <% :coordinator -> %>
            <.coordinator_message message={message} />
        <% end %>
      <% end %>
    <% end %>

    <%= if @analysis_running do %>
      <.thinking_indicator />
    <% end %>
    """
  end

  @doc """
  Empty state shown when no messages exist.
  """
  def empty_chat_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-full text-center px-8 py-12">
      <div class="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary/20 to-primary/10 flex items-center justify-center mb-6 ring-1 ring-primary/20">
        <.icon name="hero-chat-bubble-left-right" class="w-10 h-10 text-primary" />
      </div>
      <h3 class="text-lg font-semibold text-base-content mb-2">Start a conversation</h3>
      <p class="text-sm text-base-content/60 max-w-md">
        Describe what you need help with and the coordinator will analyze your system.
      </p>
    </div>
    """
  end

  @doc """
  Renders a user message as inline text (right-aligned, no bubble).
  """
  attr :message, :map, required: true

  def user_message(assigns) do
    ~H"""
    <div class="flex justify-end">
      <div class="text-right max-w-[85%]">
        <p class="text-base-content"><%= @message.content %></p>
        <time class="text-xs text-base-content/40">
          <.timestamp value={@message.timestamp} />
        </time>
      </div>
    </div>
    """
  end

  @doc """
  Renders a coordinator message in a simple bubble (left-aligned, no avatar/header).
  """
  attr :message, :map, required: true

  def coordinator_message(assigns) do
    ~H"""
    <div class="flex justify-start">
      <div class={[
        "rounded-2xl px-4 py-3 max-w-[85%]",
        message_bubble_class(@message[:message_type])
      ]}>
        <%= case @message[:message_type] do %>
          <% :insights -> %>
            <.insights_bubble insights={@message.insights} />
          <% :operator_results -> %>
            <.operator_results_bubble results={@message.operator_results} />
          <% :error -> %>
            <.error_content message={@message.content} />
          <% _ -> %>
            <div class="prose prose-sm max-w-none">
              <%= if @message[:rendered_html] do %>
                <%= Phoenix.HTML.raw(@message.rendered_html) %>
              <% else %>
                <%= @message.content %>
              <% end %>
            </div>
        <% end %>
        <time class="block text-xs text-base-content/40 mt-1">
          <.timestamp value={@message.timestamp} />
        </time>
      </div>
    </div>
    """
  end

  defp message_bubble_class(:error), do: "bg-error/10 text-error"
  defp message_bubble_class(:insights), do: "bg-base-200"
  defp message_bubble_class(:operator_results), do: "bg-base-200"
  defp message_bubble_class(_), do: "bg-base-200"

  @doc """
  Renders insights within a chat bubble.
  """
  attr :insights, :list, required: true

  def insights_bubble(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-2 text-sm font-medium text-base-content/80">
        <.icon name="hero-light-bulb" class="w-4 h-4 text-warning" />
        Found <%= length(@insights) %> insight(s)
      </div>
      <%= for insight <- @insights do %>
        <.chat_insight_card insight={insight} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders operator results within a chat bubble.
  """
  attr :results, :list, required: true

  def operator_results_bubble(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-2 text-sm font-medium text-base-content/80">
        <.icon name="hero-cpu-chip" class="w-4 h-4 text-primary" />
        Results from <%= length(@results) %> operator(s)
      </div>
      <%= for result <- @results do %>
        <.chat_operator_result result={result} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders an insight card within a chat message.
  """
  attr :insight, :map, required: true

  def chat_insight_card(assigns) do
    ~H"""
    <div class="bg-base-100 rounded-lg p-3 border border-base-300 shadow-sm">
      <div class="flex items-center gap-2 mb-2 flex-wrap">
        <.badge variant={@insight.correlation_type}><%= @insight.correlation_type %></.badge>
        <.badge variant={@insight.confidence}><%= @insight.confidence %></.badge>
      </div>
      <p class="text-sm text-base-content leading-relaxed">
        <%= @insight.summary %>
      </p>
      <%= if @insight[:root_cause_hypothesis] do %>
        <div class="mt-2 p-2 bg-base-200 rounded text-xs text-base-content/70">
          <span class="font-medium">Hypothesis:</span> <%= @insight.root_cause_hypothesis %>
        </div>
      <% end %>
      <div class="mt-2 text-xs text-base-content/50">
        <%= length(@insight[:notification_ids] || []) %> notification(s) correlated
      </div>
    </div>
    """
  end

  @doc """
  Renders an operator result within a chat message.
  """
  attr :result, :map, required: true

  def chat_operator_result(assigns) do
    notification_count = length(Map.get(assigns.result, :notifications, []))
    assigns = assign(assigns, :notification_count, notification_count)

    ~H"""
    <div class="bg-base-100 rounded-lg p-3 border border-base-300 shadow-sm">
      <div class="flex items-center justify-between mb-2">
        <span class="font-medium text-sm text-base-content">
          <%= format_skill_name(@result.skill) %>
        </span>
        <span class="badge badge-primary badge-outline badge-sm">
          <%= @notification_count %> notification(s)
        </span>
      </div>
      <%= if @notification_count > 0 do %>
        <div class="space-y-2">
          <%= for notification <- Enum.take(@result.notifications, 3) do %>
            <div class="flex items-start gap-2 text-xs p-2 bg-base-200 rounded">
              <.badge variant={notification.severity} class="shrink-0">
                <%= notification.severity %>
              </.badge>
              <span class="text-base-content/80 line-clamp-2"><%= notification.summary %></span>
            </div>
          <% end %>
          <%= if @notification_count > 3 do %>
            <div class="text-xs text-base-content/50 text-center">
              + <%= @notification_count - 3 %> more
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_skill_name(skill) when is_atom(skill) do
    skill
    |> Module.split()
    |> List.last()
  end

  defp format_skill_name(skill), do: to_string(skill)

  @doc """
  Renders an error message within a chat bubble.
  """
  attr :message, :string, required: true

  def error_content(assigns) do
    ~H"""
    <div class="flex items-start gap-2">
      <.icon name="hero-exclamation-triangle" class="w-5 h-5 shrink-0 mt-0.5" />
      <span><%= @message %></span>
    </div>
    """
  end

  @doc """
  Renders a thinking/loading indicator in the chat.
  """
  def thinking_indicator(assigns) do
    ~H"""
    <div class="flex justify-start">
      <div class="rounded-2xl px-4 py-3 bg-base-200">
        <div class="flex items-center gap-2">
          <span class="loading loading-dots loading-sm"></span>
          <span class="text-sm text-base-content/70">Analyzing...</span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the chat input area.
  """
  attr :input_text, :string, required: true
  attr :analysis_running, :boolean, default: false

  def chat_input(assigns) do
    can_send = String.trim(assigns.input_text) != "" and not assigns.analysis_running

    assigns = assign(assigns, :can_send, can_send)

    ~H"""
    <div class="p-4">
      <form phx-submit="send_message" class="flex items-end gap-3">
        <div class="flex-1">
          <textarea
            name="message"
            id="chat-input"
            rows="1"
            phx-hook=".AutoResize"
            phx-change="update_input"
            class="textarea textarea-bordered w-full resize-none min-h-[44px] max-h-32 leading-normal"
            placeholder="Describe what you need..."
            disabled={@analysis_running}
            phx-debounce="100"
          ><%= @input_text %></textarea>
        </div>

        <%= if @analysis_running do %>
          <button
            type="button"
            phx-click="stop_analysis"
            class="btn btn-error btn-circle shrink-0"
            title="Stop analysis"
          >
            <.icon name="hero-stop" class="w-5 h-5" />
          </button>
        <% else %>
          <button
            type="submit"
            class={[
              "btn btn-primary btn-circle shrink-0",
              if(not @can_send, do: "btn-disabled")
            ]}
            disabled={not @can_send}
          >
            <.icon name="hero-paper-airplane" class="w-5 h-5" />
          </button>
        <% end %>
      </form>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoResize" runtime>
      {
        mounted() {
          this.resize()
          this.el.addEventListener('input', () => this.resize())
          this.el.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              const form = this.el.closest('form')
              if (form) form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
            }
          })
        },
        updated() {
          this.resize()
        },
        resize() {
          this.el.style.height = 'auto'
          this.el.style.height = Math.min(this.el.scrollHeight, 128) + 'px'
        }
      }
    </script>
    """
  end

end

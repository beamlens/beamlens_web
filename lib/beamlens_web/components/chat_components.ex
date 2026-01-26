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
  attr(:messages, :list, required: true, doc: "List of BeamlensWeb.ChatMessage structs")
  attr(:input_text, :string, required: true)
  attr(:analysis_running, :boolean, default: false)

  def chat_container(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <%= if not Enum.empty?(@messages) do %>
        <.chat_header analysis_running={@analysis_running} />
      <% end %>

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
          this.messageCount = this.getMessageCount()
          const wasInitialized = this.el.dataset.chatInitialized === 'true'
          if (!wasInitialized) {
            this.el.dataset.chatInitialized = 'true'
            this.scrollToBottom()
          }
        },
        updated() {
          const newCount = this.getMessageCount()
          if (newCount > this.messageCount) {
            this.scrollToBottom()
            this.messageCount = newCount
          }
        },
        getMessageCount() {
          const list = this.el.querySelector('#messages-list')
          return list ? list.children.length : 0
        },
        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight
        }
      }
    </script>
    """
  end

  @doc """
  Renders the chat header with conversation controls.
  """
  attr(:analysis_running, :boolean, default: false)

  def chat_header(assigns) do
    ~H"""
    <div class="shrink-0 flex items-center justify-between px-4 py-2 border-b border-base-300 bg-base-100/80 backdrop-blur-sm">
      <div class="flex items-center gap-2 text-sm text-base-content/70">
        <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
        <span>Conversation</span>
      </div>
      <button
        type="button"
        phx-click="new_conversation"
        disabled={@analysis_running}
        class={[
          "btn btn-ghost btn-xs gap-1.5 text-base-content/60 hover:text-base-content",
          @analysis_running && "btn-disabled"
        ]}
      >
        <.icon name="hero-arrow-path" class="w-3.5 h-3.5" />
        <span>New chat</span>
      </button>
    </div>
    """
  end

  @doc """
  Renders the scrollable messages area.
  """
  attr(:messages, :list, required: true, doc: "List of BeamlensWeb.ChatMessage structs")
  attr(:analysis_running, :boolean, default: false)

  def messages_area(assigns) do
    ~H"""
    <%= if Enum.empty?(@messages) do %>
      <.empty_chat_state />
    <% else %>
      <div id="messages-list">
        <%= for message <- @messages do %>
          <div id={"message-#{message.id}"} class="mb-4">
            <%= case message.role do %>
              <% :user -> %>
                <.user_message message={message} />
              <% :coordinator -> %>
                <.coordinator_message message={message} />
            <% end %>
          </div>
        <% end %>
      </div>
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
  Renders a user message as inline text (left-aligned, no bubble).
  """
  attr(:message, :map, required: true, doc: "A BeamlensWeb.ChatMessage struct with role: :user")

  def user_message(assigns) do
    ~H"""
    <div class="flex justify-start">
      <div class="text-left max-w-[85%]">
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
  attr(:message, :map,
    required: true,
    doc: "A BeamlensWeb.ChatMessage struct with role: :coordinator"
  )

  def coordinator_message(assigns) do
    ~H"""
    <div class="flex justify-start">
      <div class={[
        "rounded-2xl px-4 py-3 max-w-[85%]",
        message_bubble_class(@message.message_type)
      ]}>
        <%= case @message.message_type do %>
          <% :insights -> %>
            <.insights_bubble insights={@message.insights} />
          <% :error -> %>
            <.error_content message={@message.content} />
          <% _ -> %>
            <div class="prose prose-sm max-w-none">
              <%= if @message.rendered_html do %>
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
  defp message_bubble_class(_), do: "bg-base-200"

  @doc """
  Renders insights within a chat bubble.
  """
  attr(:insights, :list, required: true)

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
  Renders an insight card within a chat message.
  """
  attr(:insight, :map, required: true)

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
      <%= if Map.get(@insight, :root_cause_hypothesis) do %>
        <div class="mt-2 p-2 bg-base-200 rounded text-xs text-base-content/70">
          <span class="font-medium">Hypothesis:</span> <%= @insight.root_cause_hypothesis %>
        </div>
      <% end %>
      <div class="mt-2 text-xs text-base-content/50">
        <%= length(Map.get(@insight, :notification_ids, [])) %> notification(s) correlated
      </div>
    </div>
    """
  end

  @doc """
  Renders an error message within a chat bubble.
  Shows a friendly summary with expandable details for long errors.
  """
  attr(:message, :string, required: true)

  def error_content(assigns) do
    {summary, details} = extract_error_summary(assigns.message)
    has_details = details != nil and String.length(details) > 0

    assigns =
      assigns
      |> assign(:summary, summary)
      |> assign(:details, details)
      |> assign(:has_details, has_details)

    ~H"""
    <div class="space-y-2">
      <div class="flex items-start gap-2">
        <.icon name="hero-exclamation-triangle" class="w-5 h-5 shrink-0 mt-0.5" />
        <span><%= @summary %></span>
      </div>
      <%= if @has_details do %>
        <details class="group">
          <summary class="text-xs text-base-content/50 cursor-pointer hover:text-base-content/70 flex items-center gap-1">
            <.icon name="hero-chevron-right" class="w-3 h-3 transition-transform group-open:rotate-90" />
            Show error details
          </summary>
          <div class="mt-2 p-2 bg-base-300/50 rounded text-xs font-mono overflow-x-auto max-h-32 overflow-y-auto">
            <pre class="whitespace-pre-wrap break-all"><%= @details %></pre>
          </div>
        </details>
      <% end %>
    </div>
    """
  end

  @error_truncate_length 100

  defp extract_error_summary(message) when is_binary(message) do
    if String.length(message) > @error_truncate_length do
      {String.slice(message, 0, @error_truncate_length) <> "...", message}
    else
      {message, nil}
    end
  end

  defp extract_error_summary(message), do: {inspect(message), nil}

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
  attr(:input_text, :string, required: true)
  attr(:analysis_running, :boolean, default: false)

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

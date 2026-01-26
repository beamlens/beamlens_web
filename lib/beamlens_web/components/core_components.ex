defmodule BeamlensWeb.CoreComponents do
  @moduledoc """
  Shared UI components for the BeamLens dashboard.
  """

  use Phoenix.Component

  import BeamlensWeb.Icons

  @doc """
  Renders a badge with the given variant.

  Variants are mapped to DaisyUI badge classes:
  - States: `:healthy`, `:observing`, `:warning`, `:critical`, `:idle`
  - Severities: `:info`, `:warning`, `:critical`
  - Notification statuses: `:unread`, `:acknowledged`, `:resolved`
  - Confidence: `:high`, `:medium`, `:low`
  - Correlation types: `:temporal`, `:causal`, `:pattern`
  """
  attr(:variant, :atom, required: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["badge badge-sm", variant_class(@variant), @class]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp variant_class(:healthy), do: "badge-success"
  defp variant_class(:observing), do: "badge-info"
  defp variant_class(:warning), do: "badge-warning"
  defp variant_class(:critical), do: "badge-error"
  defp variant_class(:idle), do: "badge-neutral"

  defp variant_class(:info), do: "badge-info"

  defp variant_class(:unread), do: "badge-warning"
  defp variant_class(:acknowledged), do: "badge-info"
  defp variant_class(:resolved), do: "badge-success"

  defp variant_class(:high), do: "badge-success"
  defp variant_class(:medium), do: "badge-warning"
  defp variant_class(:low), do: "badge-neutral"

  defp variant_class(:temporal), do: "badge-info"
  defp variant_class(:causal), do: "badge-primary"
  defp variant_class(:pattern), do: "badge-secondary"
  defp variant_class(:common_cause), do: "badge-accent"

  defp variant_class(_), do: "badge-neutral"

  @doc """
  Renders a status indicator dot.
  """
  attr(:running, :boolean, required: true)

  def status_dot(assigns) do
    ~H"""
    <span class={[
      "w-2 h-2 rounded-full inline-block",
      if(@running, do: "bg-success", else: "bg-error")
    ]}></span>
    """
  end

  @doc """
  Renders a card container.
  """
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-200 border border-base-300 rounded-lg overflow-hidden", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders an empty state message.
  """
  attr(:icon, :string, default: "hero-inbox")
  attr(:message, :string, required: true)

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-12 px-4 text-base-content/50">
      <.icon name={@icon} class="w-12 h-12 mx-auto mb-3 opacity-50" />
      <p><%= @message %></p>
    </div>
    """
  end

  @doc """
  Formats a DateTime for display.
  """
  def format_datetime(nil), do: "-"

  def format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  def format_datetime(other), do: inspect(other)

  @doc """
  Formats a relative time (e.g., "2 minutes ago").
  """
  def format_relative(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, dt, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  def format_relative(_), do: "-"

  @doc """
  Renders a node selector dropdown for cluster-wide monitoring.
  """
  attr(:selected_node, :atom, required: true)
  attr(:available_nodes, :list, required: true)

  def node_selector(assigns) do
    ~H"""
    <form phx-change="select_node" class="flex items-center gap-2">
      <label for="node-select" class="text-sm text-base-content/70">Node:</label>
      <select id="node-select" name="node" class="select select-sm select-bordered" aria-label="Select node">
        <%= for node <- @available_nodes do %>
          <option value={node} selected={@selected_node == node}>
            <%= format_node_name(node) %>
          </option>
        <% end %>
      </select>
    </form>
    """
  end

  @doc """
  Renders a node badge showing which node data came from.
  """
  attr(:node, :atom, required: true)

  def node_badge(assigns) do
    ~H"""
    <span class="badge badge-sm badge-ghost font-mono" title={to_string(@node)}>
      <%= format_node_name(@node) %>
    </span>
    """
  end

  @doc """
  Formats a node name for display.
  Extracts the hostname from node@host format.
  """
  def format_node_name(node) when is_atom(node) do
    node
    |> Atom.to_string()
    |> String.split("@")
    |> case do
      [name, _host] -> name
      [name] -> name
    end
  end

  def format_node_name(node), do: to_string(node)

  @doc """
  Renders a timezone toggle for switching between UTC and local time.
  Uses localStorage to persist the preference.
  """
  def timezone_toggle(assigns) do
    ~H"""
    <div
      id="timezone-toggle"
      phx-hook=".TimezoneToggle"
      class="flex items-center gap-1"
    >
      <button
        type="button"
        class="btn btn-ghost btn-sm gap-1 timezone-btn"
        data-timezone-mode="utc"
        aria-label="Toggle timezone"
      >
        <.icon name="hero-clock" class="w-4 h-4" />
        <span class="timezone-label text-xs">UTC</span>
      </button>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".TimezoneToggle" runtime>
      {
        mounted() {
          this.btn = this.el.querySelector('.timezone-btn')
          this.label = this.el.querySelector('.timezone-label')
          this.mode = localStorage.getItem('beamlens-timezone') || 'utc'
          this.updateUI()
          this.btn.addEventListener('click', () => this.toggle())
          window.addEventListener('timezone-changed', () => this.convertAllTimestamps())
          this.convertAllTimestamps()
        },
        updated() {
          this.mode = localStorage.getItem('beamlens-timezone') || 'utc'
          this.updateUI()
        },
        toggle() {
          this.mode = this.mode === 'utc' ? 'local' : 'utc'
          localStorage.setItem('beamlens-timezone', this.mode)
          this.updateUI()
          window.dispatchEvent(new CustomEvent('timezone-changed', { detail: { mode: this.mode }}))
        },
        updateUI() {
          this.btn.dataset.timezoneMode = this.mode
          if (this.mode === 'local') {
            const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
            const short = tz.split('/').pop().replace(/_/g, ' ')
            this.label.textContent = short.length > 12 ? 'Local' : short
            this.btn.title = `Showing times in ${tz}. Click for UTC.`
          } else {
            this.label.textContent = 'UTC'
            this.btn.title = 'Showing times in UTC. Click for local timezone.'
          }
          this.convertAllTimestamps()
        },
        convertAllTimestamps() {
          document.querySelectorAll('[data-utc-timestamp]').forEach(el => {
            const utc = el.dataset.utcTimestamp
            const format = el.dataset.timestampFormat || 'time'
            if (!utc) return
            const date = new Date(utc)
            if (isNaN(date.getTime())) return
            if (this.mode === 'local') {
              el.textContent = this.formatLocal(date, format)
            } else {
              el.textContent = this.formatUTC(date, format)
            }
          })
        },
        formatLocal(date, format) {
          if (format === 'time') {
            return date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
          } else if (format === 'datetime') {
            return date.toLocaleString('en-GB', {
              year: 'numeric', month: '2-digit', day: '2-digit',
              hour: '2-digit', minute: '2-digit', second: '2-digit'
            }).replace(',', '')
          } else if (format === 'full') {
            const ms = date.getMilliseconds().toString().padStart(3, '0') + '000'
            return date.toLocaleString('en-GB', {
              year: 'numeric', month: '2-digit', day: '2-digit',
              hour: '2-digit', minute: '2-digit', second: '2-digit'
            }).replace(',', '') + '.' + ms
          }
          return date.toLocaleString()
        },
        formatUTC(date, format) {
          const pad = n => n.toString().padStart(2, '0')
          if (format === 'time') {
            return `${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}`
          } else if (format === 'datetime') {
            return `${date.getUTCFullYear()}-${pad(date.getUTCMonth()+1)}-${pad(date.getUTCDate())} ${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}`
          } else if (format === 'full') {
            const ms = date.getUTCMilliseconds().toString().padStart(3, '0') + '000'
            return `${date.getUTCFullYear()}-${pad(date.getUTCMonth()+1)}-${pad(date.getUTCDate())} ${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}.${ms}`
          }
          return date.toISOString()
        }
      }
    </script>
    """
  end

  @doc """
  Renders a timestamp that can be toggled between UTC and local time.

  ## Attributes

    * `value` - DateTime to display (required)
    * `format` - Format type: :time, :datetime, or :full (default: :time)

  ## Examples

      <.timestamp value={@event.timestamp} />
      <.timestamp value={@event.timestamp} format={:datetime} />
      <.timestamp value={@event.timestamp} format={:full} />
  """
  attr(:value, :any, required: true)
  attr(:format, :atom, default: :time)

  def timestamp(assigns) do
    ~H"""
    <%= if @value do %>
      <time
        datetime={DateTime.to_iso8601(@value)}
        data-utc-timestamp={DateTime.to_iso8601(@value)}
        data-timestamp-format={@format}
      ><%= format_timestamp_initial(@value, @format) %></time>
    <% else %>
      <span>-</span>
    <% end %>
    """
  end

  defp format_timestamp_initial(%DateTime{} = dt, :time) do
    Calendar.strftime(dt, "%H:%M:%S")
  end

  defp format_timestamp_initial(%DateTime{} = dt, :datetime) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  defp format_timestamp_initial(%DateTime{} = dt, :full) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S.%f")
  end

  defp format_timestamp_initial(_, _), do: "-"

  defp dropdown_position_class("end"), do: "dropdown-end"
  defp dropdown_position_class("left"), do: "dropdown-left"
  defp dropdown_position_class("top"), do: "dropdown-top"
  defp dropdown_position_class("bottom"), do: "dropdown-bottom"
  defp dropdown_position_class(_), do: "dropdown-end"

  @doc """
  Renders a theme toggle dropdown for switching between light, dark, and system modes.

  ## Attributes

    * `position` - Dropdown position: "end" (default), "left", "top", "bottom"
  """
  attr(:position, :string, default: "end")

  def theme_toggle(assigns) do
    ~H"""
    <div class={["dropdown", dropdown_position_class(@position)]}>
      <div tabindex="0" role="button" aria-label="Toggle theme" class="btn btn-ghost btn-sm btn-circle">
        <.icon name="hero-sun" class="w-5 h-5 theme-icon-light" />
        <.icon name="hero-moon" class="w-5 h-5 theme-icon-dark" />
        <.icon name="hero-computer-desktop" class="w-5 h-5 theme-icon-system" />
      </div>
      <ul tabindex="0" class="dropdown-content z-50 menu p-2 shadow-lg bg-base-200 rounded-box w-36">
        <li>
          <a onclick="setTheme('light')" class="flex gap-2">
            <.icon name="hero-sun" class="w-4 h-4" />
            Light
          </a>
        </li>
        <li>
          <a onclick="setTheme('dark')" class="flex gap-2">
            <.icon name="hero-moon" class="w-4 h-4" />
            Dark
          </a>
        </li>
        <li>
          <a onclick="setTheme('system')" class="flex gap-2">
            <.icon name="hero-computer-desktop" class="w-4 h-4" />
            System
          </a>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a copyable text field with hover icon/underline and "Copied!" tooltip feedback.

  When hovered, shows a clipboard icon and underlines the text.
  When clicked, copies the value to clipboard and shows a "Copied!" tooltip.

  ## Attributes

    * `value` - The text to copy (required)
    * `display` - Optional truncated/formatted display text (defaults to value)
    * `class` - Additional CSS classes
    * `code` - Use monospace code styling (default: false)

  ## Examples

      <.copyable value={@event.id} />
      <.copyable value={@event.trace_id} display={String.slice(@event.trace_id, 0..7) <> "..."} />
      <.copyable value={@notification.observation} />
  """
  attr(:value, :string, required: true)
  attr(:display, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:code, :boolean, default: false)

  def copyable(assigns) do
    copy_id = "copy-#{:erlang.phash2(assigns.value)}"
    assigns = assign(assigns, :copy_id, copy_id)

    ~H"""
    <span
      class={[
        "copyable-field relative inline-flex items-center gap-1",
        @class
      ]}
      onclick={"copyToClipboard(this, '#{@copy_id}')"}
      data-copy-text={@value}
      data-copy-id={@copy_id}
    >
      <span class={[
        "copyable-text",
        @code && "font-mono text-xs bg-base-300 px-1.5 py-0.5 rounded text-secondary"
      ]}>
        <%= @display || @value %>
      </span>
      <span class="copy-icon w-4 h-4 shrink-0" style="opacity: 0; transition: opacity 0.15s;">
        <.icon name="hero-clipboard-document" class="w-4 h-4" />
      </span>
    </span>
    """
  end

  @doc """
  Renders a copy icon button for copying entire records as JSON.

  ## Attributes

    * `data` - Map data to copy as JSON (required)

  ## Examples

      <.copy_all_button data={%{id: @event.id, name: @event.name}} />
      <.copy_all_button data={@notification} />
  """
  attr(:data, :map, required: true)

  def copy_all_button(assigns) do
    copy_id = "copy-btn-#{:erlang.phash2(assigns.data)}"
    assigns = assign(assigns, :copy_id, copy_id)

    ~H"""
    <button
      type="button"
      class="btn btn-ghost btn-xs btn-square copy-record-btn opacity-50 hover:opacity-100 transition-opacity cursor-pointer"
      onclick={"copyRecordToClipboard(this)"}
      data-copy-json={Jason.encode!(@data)}
      title="Copy as JSON"
    >
      <.icon name="hero-clipboard-document" class="w-4 h-4 copy-icon" />
      <.icon name="hero-check" class="w-4 h-4 check-icon hidden" />
    </button>
    """
  end
end

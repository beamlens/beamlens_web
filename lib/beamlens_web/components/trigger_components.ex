defmodule BeamlensWeb.TriggerComponents do
  @moduledoc """
  Components for the trigger-based analysis interface.
  """

  use Phoenix.Component

  import BeamlensWeb.CoreComponents
  import BeamlensWeb.Icons

  @doc """
  Renders the trigger analysis form.
  """
  attr(:trigger_context, :string, required: true)
  attr(:available_skills, :list, required: true)
  attr(:selected_skills, :list, required: true)
  attr(:analysis_running, :boolean, required: true)

  def trigger_form(assigns) do
    can_trigger = length(assigns.selected_skills) > 0 and not assigns.analysis_running

    assigns = assign(assigns, :can_trigger, can_trigger)

    ~H"""
    <div class="group relative overflow-hidden rounded-2xl bg-base-100 border border-base-300 shadow-lg hover:shadow-xl hover:border-primary/30 transition-all duration-300">
      <%!-- Subtle gradient background --%>
      <div class="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

      <div class="relative px-5 py-4 md:px-6 md:py-5 border-b border-base-300/50 flex items-center justify-between">
        <h2 class="text-lg font-bold text-base-content flex items-center gap-3">
          <span class="w-10 h-10 rounded-xl bg-gradient-to-br from-primary/20 to-primary/10 flex items-center justify-center shadow-sm ring-1 ring-primary/20">
            <.icon name="hero-bolt" class="w-5 h-5 text-primary" />
          </span>
          <span>Trigger Analysis</span>
        </h2>
        <div class="flex items-center gap-2 text-sm">
          <%= if @analysis_running do %>
            <span class="flex items-center gap-2 text-primary font-medium">
              <span class="loading loading-spinner loading-xs"></span>
              Running...
            </span>
          <% else %>
            <span class="badge badge-primary badge-outline badge-sm font-medium">
              <%= length(@selected_skills) %> selected
            </span>
          <% end %>
        </div>
      </div>

      <div class="relative p-5 md:p-6 space-y-6">
        <div>
          <label for="trigger-context" class="text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-3 block flex items-center gap-2">
            <.icon name="hero-document-text" class="w-4 h-4 text-primary/60" />
            Analysis Context
          </label>
          <form phx-change="update_trigger_context">
            <textarea
              id="trigger-context"
              name="context"
              rows="3"
              phx-debounce="300"
              class="textarea w-full text-base-content bg-base-200/50 border-base-300 focus:border-primary focus:bg-base-100 focus:ring-2 focus:ring-primary/20 rounded-xl transition-all duration-200 placeholder:text-base-content/40"
              placeholder="Describe what you want to investigate (e.g., 'High memory usage detected', 'Check system health', 'Investigate slow queries')..."
              disabled={@analysis_running}
            ><%= @trigger_context %></textarea>
          </form>
        </div>

        <div>
          <div class="flex items-center justify-between mb-4">
            <label class="text-xs font-semibold text-base-content/60 uppercase tracking-wider flex items-center gap-2">
              <.icon name="hero-cpu-chip" class="w-4 h-4 text-primary/60" />
              Skills to Invoke
            </label>
            <div class="flex items-center gap-2">
              <button
                type="button"
                phx-click="select_all_skills"
                class="text-xs font-medium text-primary/70 hover:text-primary transition-colors"
                disabled={@analysis_running}
              >
                Select All
              </button>
              <span class="text-base-content/20">•</span>
              <button
                type="button"
                phx-click="deselect_all_skills"
                class="text-xs font-medium text-base-content/50 hover:text-base-content/70 transition-colors"
                disabled={@analysis_running}
              >
                Clear
              </button>
            </div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
            <%= for skill <- @available_skills do %>
              <.skill_checkbox
                skill={skill}
                selected={skill.module in @selected_skills}
                disabled={@analysis_running}
              />
            <% end %>
          </div>
          <%= if Enum.empty?(@available_skills) do %>
            <div class="text-center py-12 text-base-content/50">
              <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-base-200 flex items-center justify-center">
                <.icon name="hero-cpu-chip" class="w-8 h-8 opacity-40" />
              </div>
              <p class="text-sm font-medium">No skills available</p>
              <p class="text-xs mt-1 text-base-content/40">Check your beamlens configuration</p>
            </div>
          <% end %>
        </div>

        <div class="flex justify-end pt-4 border-t border-base-300/50">
          <button
            type="button"
            phx-click="trigger_analysis"
            class={[
              "btn btn-primary gap-2 px-6 shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/30 hover:scale-[1.02] transition-all duration-200",
              if(not @can_trigger, do: "btn-disabled opacity-50 shadow-none")
            ]}
            disabled={not @can_trigger}
          >
            <%= if @analysis_running do %>
              <span class="loading loading-spinner loading-sm"></span>
              Running Analysis...
            <% else %>
              <.icon name="hero-bolt" class="w-5 h-5" />
              Trigger Analysis
            <% end %>
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a skill selection checkbox.
  """
  attr(:skill, :map, required: true)
  attr(:selected, :boolean, required: true)
  attr(:disabled, :boolean, default: false)

  def skill_checkbox(assigns) do
    ~H"""
    <label class={[
      "group relative flex items-start gap-3 p-4 rounded-xl cursor-pointer transition-all duration-300",
      "border overflow-hidden",
      if(@selected,
        do: "bg-gradient-to-br from-primary/15 to-primary/5 border-primary/40 shadow-md ring-1 ring-primary/20",
        else: "bg-base-100 border-base-300 hover:border-primary/30 hover:bg-base-200/30 hover:shadow-sm"
      ),
      if(@disabled, do: "opacity-50 cursor-not-allowed pointer-events-none")
    ]}>
      <%!-- Selection indicator bar --%>
      <div class={[
        "absolute left-0 top-0 bottom-0 w-1 transition-all duration-300",
        if(@selected, do: "bg-primary", else: "bg-transparent group-hover:bg-primary/30")
      ]}></div>

      <div class={[
        "w-5 h-5 rounded-md border-2 flex items-center justify-center shrink-0 mt-0.5 transition-all duration-200",
        if(@selected,
          do: "bg-primary border-primary",
          else: "border-base-300 group-hover:border-primary/50"
        )
      ]}>
        <%= if @selected do %>
          <.icon name="hero-check" class="w-3.5 h-3.5 text-primary-content transition-all duration-200 opacity-100 scale-100" />
        <% else %>
          <.icon name="hero-check" class="w-3.5 h-3.5 text-primary-content transition-all duration-200 opacity-0 scale-75" />
        <% end %>
      </div>
      <input
        type="checkbox"
        class="hidden"
        checked={@selected}
        phx-click="toggle_skill"
        phx-value-skill={@skill.module}
        disabled={@disabled}
      />
      <div class="flex-1 min-w-0 pl-1">
        <div class={[
          "font-semibold text-sm truncate transition-colors",
          if(@selected, do: "text-base-content", else: "text-base-content/80 group-hover:text-base-content")
        ]}>
          <%= @skill.title %>
        </div>
        <div class="text-xs text-base-content/50 line-clamp-2 mt-1 leading-relaxed">
          <%= @skill.description %>
        </div>
      </div>
    </label>
    """
  end

  @doc """
  Renders the analysis results section.
  """
  attr(:result, :map, default: nil)
  attr(:analysis_running, :boolean, required: true)

  def analysis_results(assigns) do
    ~H"""
    <%= if @result do %>
      <div class="group relative overflow-hidden rounded-2xl bg-base-100 border border-success/30 shadow-lg mt-6">
        <%!-- Success gradient background --%>
        <div class="absolute inset-0 bg-gradient-to-br from-success/5 via-transparent to-primary/5"></div>

        <div class="relative px-5 py-4 md:px-6 md:py-5 border-b border-base-300/50 flex items-center justify-between">
          <h2 class="text-lg font-bold text-base-content flex items-center gap-3">
            <span class="w-10 h-10 rounded-xl bg-gradient-to-br from-success/20 to-success/10 flex items-center justify-center shadow-sm ring-1 ring-success/20">
              <.icon name="hero-clipboard-document-check" class="w-5 h-5 text-success" />
            </span>
            <span>Analysis Results</span>
          </h2>
          <button
            type="button"
            phx-click="clear_results"
            class="btn btn-ghost btn-sm gap-2 text-base-content/60 hover:text-base-content hover:bg-base-200/50 transition-all"
          >
            <.icon name="hero-x-mark" class="w-4 h-4" />
            Clear
          </button>
        </div>

        <div class="relative p-5 md:p-6 space-y-8">
          <div>
            <div class="flex items-center justify-between mb-4 pb-3 border-b border-base-300/50">
              <h3 class="text-sm font-semibold text-base-content flex items-center gap-2">
                <.icon name="hero-light-bulb" class="w-4 h-4 text-warning" />
                Insights
              </h3>
              <span class="badge badge-warning badge-outline badge-sm font-medium"><%= length(@result.insights) %></span>
            </div>
            <%= if Enum.empty?(@result.insights) do %>
              <div class="text-center py-10 text-base-content/50">
                <div class="w-14 h-14 mx-auto mb-3 rounded-xl bg-base-200 flex items-center justify-center">
                  <.icon name="hero-light-bulb" class="w-7 h-7 opacity-40" />
                </div>
                <p class="text-sm font-medium">No insights produced</p>
                <p class="text-xs mt-1 text-base-content/40">Try running with different skills or context</p>
              </div>
            <% else %>
              <div class="space-y-4">
                <%= for insight <- @result.insights do %>
                  <.result_insight_card insight={insight} />
                <% end %>
              </div>
            <% end %>
          </div>

        </div>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders an insight card in the results section.
  """
  attr(:insight, :map, required: true)

  def result_insight_card(assigns) do
    ~H"""
    <div class="group relative rounded-xl bg-base-100 border border-base-300 shadow-sm hover:shadow-md hover:border-primary/30 transition-all duration-300 overflow-hidden">
      <%!-- Accent bar --%>
      <div class="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-warning to-warning/50"></div>

      <div class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        <.copy_all_button data={maybe_struct_to_map(@insight)} />
      </div>
      <div class="px-5 py-4 border-b border-base-300/50 flex items-center gap-2 flex-wrap pr-14">
        <.badge variant={@insight.correlation_type}><%= @insight.correlation_type %></.badge>
        <.badge variant={@insight.confidence}><%= @insight.confidence %></.badge>
        <span class="flex-1"></span>
        <.copyable value={@insight.id} display={String.slice(@insight.id, 0..7) <> "..."} code={true} />
      </div>
      <div class="px-5 py-4">
        <p class="text-sm text-base-content leading-relaxed mb-4">
          <.copyable value={@insight.summary} code={false} class="text-base-content" />
        </p>
        <%= if @insight.root_cause_hypothesis do %>
          <div class="bg-gradient-to-br from-base-200/80 to-base-200/50 p-4 rounded-lg text-sm mb-4 border border-base-300/50">
            <div class="text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-2 flex items-center gap-2">
              <.icon name="hero-magnifying-glass" class="w-3.5 h-3.5" />
              Root Cause Hypothesis
            </div>
            <div class="text-base-content/80 leading-relaxed">
              <.copyable value={@insight.root_cause_hypothesis} code={false} />
            </div>
          </div>
        <% end %>
        <div class="flex flex-wrap gap-3 text-xs text-base-content/50">
          <span class="flex items-center gap-1.5 px-2 py-1 rounded-md bg-base-200/50">
            <.icon name="hero-link" class="w-3.5 h-3.5 text-primary/60" />
            <%= length(@insight.notification_ids) %> notification(s) correlated
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp maybe_struct_to_map(%{__struct__: _} = struct), do: Map.from_struct(struct)
  defp maybe_struct_to_map(map) when is_map(map), do: map
end

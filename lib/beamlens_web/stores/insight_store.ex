defmodule BeamlensWeb.InsightStore do
  @moduledoc """
  ETS-based store for insights produced by the BeamLens coordinator.

  Subscribes to `[:beamlens, :coordinator, :insight_produced]` telemetry events
  and stores insights for display in the dashboard.
  """

  use GenServer

  @table_name :beamlens_web_insights
  @telemetry_handler_id "beamlens-web-insight-store"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all insights, sorted by creation time (newest first).
  """
  def list_insights do
    :ets.tab2list(@table_name)
    |> Enum.map(fn {_id, insight} -> insight end)
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
  end

  @doc """
  Returns the count of insights.
  """
  def count do
    :ets.info(@table_name, :size)
  end

  @doc """
  Gets a single insight by ID.
  """
  def get_insight(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, insight}] -> {:ok, insight}
      [] -> {:error, :not_found}
    end
  end

  @doc false

  def insights_callback do
    list_insights()
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    :telemetry.attach(
      @telemetry_handler_id,
      [:beamlens, :coordinator, :insight_produced],
      &__MODULE__.handle_telemetry_event/4,
      nil
    )

    {:ok, %{table: table}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@telemetry_handler_id)
  end

  @doc false
  def handle_telemetry_event(_event, _measurements, %{insight: insight}, _config) do
    insight_data = %{
      id: insight.id,
      notification_ids: insight.notification_ids,
      correlation_type: insight.correlation_type,
      summary: insight.summary,
      matched_observations: insight.matched_observations,
      hypothesis_grounded: insight.hypothesis_grounded,
      root_cause_hypothesis: insight.root_cause_hypothesis,
      confidence: insight.confidence,
      created_at: insight.created_at
    }

    :ets.insert(@table_name, {insight.id, insight_data})
  end
end

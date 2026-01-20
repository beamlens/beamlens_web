defmodule BeamlensWeb.EventStore do
  @moduledoc """
  ETS-based store for telemetry events from BeamLens operators and coordinator.

  Provides an audit trail of system activity with a ring buffer to prevent
  unbounded memory growth. Subscribes to key telemetry events and stores
  them for display in the dashboard.
  """

  use GenServer

  @table_name :beamlens_web_events
  @max_events 500
  @telemetry_handler_id "beamlens-web-event-store"

  # Events to capture
  @operator_events [
    [:beamlens, :operator, :iteration_start],
    [:beamlens, :operator, :state_change],
    [:beamlens, :operator, :notification_sent],
    [:beamlens, :operator, :get_notifications],
    [:beamlens, :operator, :take_snapshot],
    [:beamlens, :operator, :get_snapshot],
    [:beamlens, :operator, :get_snapshots],
    [:beamlens, :operator, :execute_start],
    [:beamlens, :operator, :execute_complete],
    [:beamlens, :operator, :execute_error],
    [:beamlens, :operator, :wait],
    [:beamlens, :operator, :think],
    [:beamlens, :operator, :llm_error]
  ]

  @coordinator_events [
    [:beamlens, :coordinator, :notification_received],
    [:beamlens, :coordinator, :iteration_start],
    [:beamlens, :coordinator, :get_notifications],
    [:beamlens, :coordinator, :update_notification_statuses],
    [:beamlens, :coordinator, :insight_produced],
    [:beamlens, :coordinator, :done],
    [:beamlens, :coordinator, :think],
    [:beamlens, :coordinator, :llm_error]
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all events, optionally filtered by source (operator name or :coordinator).
  Events are returned newest first.
  """
  def list_events(source \\ nil) do
    events =
      :ets.tab2list(@table_name)
      |> Enum.map(fn {_id, event} -> event end)
      |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    case source do
      nil -> events
      source -> Enum.filter(events, &(&1.source == source))
    end
  end

  @doc """
  Returns the count of stored events.
  """
  def count do
    :ets.info(@table_name, :size)
  end

  @doc false

  def events_callback(source \\ nil) do
    list_events(source)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    all_events = @operator_events ++ @coordinator_events

    :telemetry.attach_many(
      @telemetry_handler_id,
      all_events,
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
  def handle_telemetry_event(event_name, measurements, metadata, _config) do
    event = build_event(event_name, measurements, metadata)
    :ets.insert(@table_name, {event.id, event})
    enforce_max_events()
  end

  defp build_event(event_name, measurements, metadata) do
    %{
      id: generate_id(),
      timestamp: timestamp_from_measurements(measurements),
      event_name: event_name,
      event_type: event_type(event_name),
      source: extract_source(event_name, metadata),
      trace_id: Map.get(metadata, :trace_id),
      metadata: sanitize_metadata(event_name, metadata)
    }
  end

  defp timestamp_from_measurements(%{system_time: system_time}) do
    DateTime.from_unix!(system_time, :native)
  end

  defp timestamp_from_measurements(_), do: DateTime.utc_now()

  defp event_type([:beamlens, :operator, type]), do: type
  defp event_type([:beamlens, :coordinator, type]), do: type
  defp event_type(_), do: :unknown

  defp extract_source([:beamlens, :operator, _], metadata),
    do: Map.get(metadata, :operator, :unknown)

  defp extract_source([:beamlens, :coordinator, _], _metadata), do: :coordinator
  defp extract_source(_, _), do: :unknown

  defp sanitize_metadata([:beamlens, :operator, :iteration_start], meta) do
    %{iteration: meta[:iteration], operator_state: meta[:operator_state]}
  end

  defp sanitize_metadata([:beamlens, :operator, :state_change], meta) do
    %{from: meta[:from], to: meta[:to], reason: meta[:reason]}
  end

  defp sanitize_metadata([:beamlens, :operator, :notification_sent], meta) do
    notification = meta[:notification]

    %{
      notification_id: notification.id,
      severity: notification.severity,
      anomaly_type: notification.anomaly_type
    }
  end

  defp sanitize_metadata([:beamlens, :operator, :take_snapshot], meta) do
    %{snapshot_id: meta[:snapshot_id]}
  end

  defp sanitize_metadata([:beamlens, :operator, :get_notifications], meta) do
    %{count: meta[:count]}
  end

  defp sanitize_metadata([:beamlens, :operator, :get_snapshot], meta) do
    %{snapshot_id: meta[:snapshot_id]}
  end

  defp sanitize_metadata([:beamlens, :operator, :get_snapshots], meta) do
    %{count: meta[:count]}
  end

  defp sanitize_metadata([:beamlens, :operator, :execute_start], meta) do
    %{code: meta[:code]}
  end

  defp sanitize_metadata([:beamlens, :operator, :execute_complete], meta) do
    %{code: meta[:code], result: inspect(meta[:result])}
  end

  defp sanitize_metadata([:beamlens, :operator, :execute_error], meta) do
    %{code: meta[:code], reason: inspect(meta[:reason])}
  end

  defp sanitize_metadata([:beamlens, :operator, :wait], meta) do
    %{ms: meta[:ms]}
  end

  defp sanitize_metadata([:beamlens, :operator, :think], meta) do
    %{thought: meta[:thought]}
  end

  defp sanitize_metadata([:beamlens, :operator, :llm_error], meta) do
    %{
      reason: inspect(meta[:reason]),
      retry_count: meta[:retry_count],
      will_retry: meta[:will_retry]
    }
  end

  defp sanitize_metadata([:beamlens, :coordinator, :notification_received], meta) do
    %{notification_id: meta[:notification_id], operator: meta[:operator]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :iteration_start], meta) do
    %{iteration: meta[:iteration], notification_count: meta[:notification_count]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :get_notifications], meta) do
    %{count: meta[:count], status: meta[:status]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :update_notification_statuses], meta) do
    %{count: meta[:count], status: meta[:status]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :insight_produced], meta) do
    insight = meta[:insight]

    %{
      insight_id: insight.id,
      correlation_type: insight.correlation_type,
      summary: insight.summary,
      root_cause_hypothesis: insight.root_cause_hypothesis,
      confidence: insight.confidence,
      notification_count: length(insight.notification_ids)
    }
  end

  defp sanitize_metadata([:beamlens, :coordinator, :done], meta) do
    %{has_unread: meta[:has_unread]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :think], meta) do
    %{thought: meta[:thought]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :llm_error], meta) do
    %{reason: inspect(meta[:reason])}
  end

  defp sanitize_metadata(_, _), do: %{}

  defp enforce_max_events do
    size = :ets.info(@table_name, :size)

    if size > @max_events do
      events =
        :ets.tab2list(@table_name)
        |> Enum.map(fn {id, event} -> {id, event.timestamp} end)
        |> Enum.sort_by(fn {_id, ts} -> ts end, {:asc, DateTime})

      events_to_delete = Enum.take(events, size - @max_events)

      Enum.each(events_to_delete, fn {id, _ts} ->
        :ets.delete(@table_name, id)
      end)
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end

defmodule BeamlensWeb.EventStore do
  @moduledoc """
  ETS-based store for telemetry events from BeamLens watchers and coordinator.

  Provides an audit trail of system activity with a ring buffer to prevent
  unbounded memory growth. Subscribes to key telemetry events and stores
  them for display in the dashboard.
  """

  use GenServer

  @table_name :beamlens_web_events
  @max_events 500
  @telemetry_handler_id "beamlens-web-event-store"

  # Events to capture
  @watcher_events [
    [:beamlens, :watcher, :iteration_start],
    [:beamlens, :watcher, :state_change],
    [:beamlens, :watcher, :alert_fired],
    [:beamlens, :watcher, :take_snapshot],
    [:beamlens, :watcher, :wait],
    [:beamlens, :watcher, :think],
    [:beamlens, :watcher, :llm_error]
  ]

  @coordinator_events [
    [:beamlens, :coordinator, :alert_received],
    [:beamlens, :coordinator, :iteration_start],
    [:beamlens, :coordinator, :insight_produced],
    [:beamlens, :coordinator, :done]
  ]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all events, optionally filtered by source (watcher name or :coordinator).
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
  # RPC callback for remote node queries
  def events_callback(source \\ nil) do
    list_events(source)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    # Subscribe to all tracked events
    all_events = @watcher_events ++ @coordinator_events

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

  defp event_type([:beamlens, :watcher, type]), do: type
  defp event_type([:beamlens, :coordinator, type]), do: type
  defp event_type(_), do: :unknown

  defp extract_source([:beamlens, :watcher, _], metadata),
    do: Map.get(metadata, :watcher, :unknown)

  defp extract_source([:beamlens, :coordinator, _], _metadata), do: :coordinator
  defp extract_source(_, _), do: :unknown

  # Extract only the relevant metadata for display
  defp sanitize_metadata([:beamlens, :watcher, :iteration_start], meta) do
    %{iteration: meta[:iteration], watcher_state: meta[:watcher_state]}
  end

  defp sanitize_metadata([:beamlens, :watcher, :state_change], meta) do
    %{from: meta[:from], to: meta[:to], reason: meta[:reason]}
  end

  defp sanitize_metadata([:beamlens, :watcher, :alert_fired], meta) do
    alert = meta[:alert]
    %{alert_id: alert.id, severity: alert.severity, anomaly_type: alert.anomaly_type}
  end

  defp sanitize_metadata([:beamlens, :watcher, :take_snapshot], meta) do
    %{snapshot_id: meta[:snapshot_id]}
  end

  defp sanitize_metadata([:beamlens, :watcher, :wait], meta) do
    %{ms: meta[:ms]}
  end

  defp sanitize_metadata([:beamlens, :watcher, :think], meta) do
    %{thought: meta[:thought]}
  end

  defp sanitize_metadata([:beamlens, :watcher, :llm_error], meta) do
    %{reason: inspect(meta[:reason])}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :alert_received], meta) do
    %{alert_id: meta[:alert_id], watcher: meta[:watcher]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :iteration_start], meta) do
    %{iteration: meta[:iteration], alert_count: meta[:alert_count]}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :insight_produced], meta) do
    insight = meta[:insight]
    %{insight_id: insight.id, correlation_type: insight.correlation_type}
  end

  defp sanitize_metadata([:beamlens, :coordinator, :done], meta) do
    %{has_unread: meta[:has_unread]}
  end

  defp sanitize_metadata(_, _), do: %{}

  defp enforce_max_events do
    size = :ets.info(@table_name, :size)

    if size > @max_events do
      # Get all events, sort by timestamp, delete oldest
      events =
        :ets.tab2list(@table_name)
        |> Enum.map(fn {id, event} -> {id, event.timestamp} end)
        |> Enum.sort_by(fn {_id, ts} -> ts end, {:asc, DateTime})

      # Delete oldest events to get back to max
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

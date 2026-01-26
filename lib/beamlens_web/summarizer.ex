defmodule BeamlensWeb.Summarizer do
  @moduledoc """
  Generates natural language summaries of analysis results using BAML.

  Integrates with Puck.Compaction to automatically compact conversation
  history when it gets too long, preserving context while managing token usage.
  """

  alias Puck.Context
  alias Puck.Compaction.Summarize, as: SummarizeCompaction

  @compaction_threshold 10
  @keep_last_messages 3

  @doc """
  Summarizes analysis results into a conversational response.

  Takes the user's original question, the structured analysis result,
  and a Puck.Context for conversation history.

  Automatically compacts the conversation history if it exceeds the threshold.

  Returns `{:ok, summary, updated_context}` or `{:error, reason}`.
  """
  def summarize(user_question, result, %Context{} = context) do
    client_registry = BeamlensWeb.Config.client_registry()

    if client_registry == %{} do
      :telemetry.execute(
        [:beamlens_web, :summarizer, :error],
        %{system_time: System.system_time()},
        %{reason: :no_client_registry}
      )

      {:error, :no_client_registry}
    else
      context = maybe_compact_context(context, client_registry)

      analysis_data = format_analysis_data(result)
      conversation_history = format_context_history(context)

      case call_summarize(client_registry, user_question, analysis_data, conversation_history) do
        {:ok, summary} ->
          updated_context = Context.add_message(context, :assistant, summary)
          {:ok, summary, updated_context}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp maybe_compact_context(context, client_registry) do
    message_count = Context.message_count(context)

    if message_count > @compaction_threshold do
      :telemetry.execute(
        [:beamlens_web, :summarizer, :compaction, :start],
        %{system_time: System.system_time()},
        %{message_count: message_count}
      )

      compaction_config = %{
        client_registry: client_registry,
        keep_last: @keep_last_messages
      }

      case Puck.Compaction.compact(context, {SummarizeCompaction, compaction_config}) do
        {:ok, compacted_context} ->
          new_count = Context.message_count(compacted_context)

          :telemetry.execute(
            [:beamlens_web, :summarizer, :compaction, :complete],
            %{system_time: System.system_time()},
            %{original_count: message_count, new_count: new_count}
          )

          compacted_context

        {:error, reason} ->
          :telemetry.execute(
            [:beamlens_web, :summarizer, :compaction, :error],
            %{system_time: System.system_time()},
            %{reason: reason}
          )

          context
      end
    else
      context
    end
  end

  defp format_context_history(context) do
    context
    |> Context.messages()
    |> Enum.map(&format_puck_message/1)
    |> Enum.join("\n\n")
  end

  defp format_puck_message(%Puck.Message{role: role, content: parts}) do
    role_label = if role == :user, do: "User", else: "Assistant"

    content_text =
      parts
      |> Enum.map(&extract_text_content/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    "#{role_label}: #{content_text}"
  end

  defp extract_text_content(%{type: :text, text: text}), do: text
  defp extract_text_content(_), do: nil

  defp call_summarize(client_registry, user_question, analysis_data, conversation_history) do
    backend_config = %{
      function: "SummarizeAnalysis",
      args: %{
        user_question: user_question,
        analysis_data: analysis_data,
        conversation_history: conversation_history
      },
      client_registry: client_registry,
      path: Application.app_dir(:beamlens_web, "priv/baml_src")
    }

    client = Puck.Client.new({Puck.Backends.Baml, backend_config})
    context = Puck.Context.new()

    case Puck.call(client, "", context) do
      {:ok, %Puck.Response{content: content}, _ctx} ->
        {:ok, content}

      {:error, reason} ->
        :telemetry.execute(
          [:beamlens_web, :summarizer, :llm_call, :error],
          %{system_time: System.system_time()},
          %{reason: reason}
        )

        {:error, reason}
    end
  end

  @doc false
  def format_analysis_data(result) do
    insights = Map.get(result, :insights, [])
    operator_results = Map.get(result, :operator_results, [])

    parts = []

    parts =
      if length(insights) > 0 do
        insight_text =
          insights
          |> Enum.map(fn insight ->
            confidence = Map.get(insight, :confidence, :unknown)
            summary = Map.get(insight, :summary, "No summary")
            hypothesis = Map.get(insight, :root_cause_hypothesis)

            base = "- [#{confidence}] #{summary}"

            if hypothesis do
              base <> "\n  Hypothesis: #{hypothesis}"
            else
              base
            end
          end)
          |> Enum.join("\n")

        parts ++ ["## Insights\n#{insight_text}"]
      else
        parts
      end

    parts =
      if length(operator_results) > 0 do
        operator_text =
          operator_results
          |> Enum.map(fn result ->
            skill = result.skill |> Module.split() |> List.last()
            state = Map.get(result, :state, :unknown)
            notifications = Map.get(result, :notifications, [])
            snapshots = Map.get(result, :snapshots, [])

            notif_text =
              if length(notifications) > 0 do
                notifications
                |> Enum.map(fn n ->
                  severity = Map.get(n, :severity, :info)
                  observation = Map.get(n, :observation, "")
                  context = Map.get(n, :context)
                  hypothesis = Map.get(n, :hypothesis)

                  base = "  - [#{severity}] #{observation}"
                  base = if context, do: base <> " (Context: #{context})", else: base
                  if hypothesis, do: base <> "\n    Hypothesis: #{hypothesis}", else: base
                end)
                |> Enum.join("\n")
              else
                nil
              end

            snapshot_text =
              if length(snapshots) > 0 do
                snapshot = List.first(snapshots)
                data = Map.get(snapshot, :data, %{})

                data
                |> Enum.take(5)
                |> Enum.map(fn {k, v} -> "  - #{k}: #{inspect(v)}" end)
                |> Enum.join("\n")
              else
                nil
              end

            lines = ["### #{skill} (#{state})"]
            lines = if notif_text, do: lines ++ [notif_text], else: lines
            lines = if snapshot_text, do: lines ++ ["Metrics:", snapshot_text], else: lines
            Enum.join(lines, "\n")
          end)
          |> Enum.join("\n\n")

        parts ++ ["## Operator Results\n#{operator_text}"]
      else
        parts
      end

    if Enum.empty?(parts) do
      "No significant findings from the analysis."
    else
      Enum.join(parts, "\n\n")
    end
  end
end

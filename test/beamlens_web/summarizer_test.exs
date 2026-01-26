defmodule BeamlensWeb.SummarizerTest do
  use ExUnit.Case
  alias BeamlensWeb.Summarizer
  alias BeamlensWeb.Config
  alias Puck.Context

  setup do
    :persistent_term.erase({Config, :client_registry})
    :ok
  end

  describe "summarize/3" do
    test "returns error when client_registry is empty" do
      :persistent_term.put({Config, :client_registry}, %{})
      context = Context.new()

      assert {:error, :no_client_registry} =
               Summarizer.summarize("test question", %{}, context)
    end

    test "emits telemetry event when client_registry is empty" do
      :persistent_term.put({Config, :client_registry}, %{})

      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:beamlens_web, :summarizer, :error]
        ])

      context = Context.new()
      Summarizer.summarize("test question", %{}, context)

      assert_received {[:beamlens_web, :summarizer, :error], ^ref, %{system_time: _},
                       %{reason: :no_client_registry}}
    end
  end

  describe "format_analysis_data/1" do
    test "returns default message for empty results" do
      result = %{}

      assert Summarizer.format_analysis_data(result) ==
               "No significant findings from the analysis."
    end

    test "returns default message when insights and operator_results are empty lists" do
      result = %{insights: [], operator_results: []}

      assert Summarizer.format_analysis_data(result) ==
               "No significant findings from the analysis."
    end

    test "formats insights only" do
      result = %{
        insights: [
          %{
            confidence: :high,
            summary: "Memory usage is abnormally high",
            root_cause_hypothesis: "Memory leak in GenServer"
          },
          %{
            confidence: :medium,
            summary: "Process count increasing"
          }
        ]
      }

      output = Summarizer.format_analysis_data(result)

      assert String.contains?(output, "## Insights")
      assert String.contains?(output, "[high] Memory usage is abnormally high")
      assert String.contains?(output, "Hypothesis: Memory leak in GenServer")
      assert String.contains?(output, "[medium] Process count increasing")
      refute String.contains?(output, "## Operator Results")
    end

    test "formats operator_results only" do
      result = %{
        operator_results: [
          %{
            skill: MyApp.Skills.Memory,
            state: :completed,
            notifications: [
              %{
                severity: :warning,
                observation: "High memory detected",
                context: "Node running for 2 days",
                hypothesis: "ETS table growth"
              }
            ],
            snapshots: [
              %{data: %{heap_size: 1024, stack_size: 256}}
            ]
          }
        ]
      }

      output = Summarizer.format_analysis_data(result)

      assert String.contains?(output, "## Operator Results")
      assert String.contains?(output, "### Memory (completed)")
      assert String.contains?(output, "[warning] High memory detected")
      assert String.contains?(output, "Context: Node running for 2 days")
      assert String.contains?(output, "Hypothesis: ETS table growth")
      assert String.contains?(output, "heap_size:")
      refute String.contains?(output, "## Insights")
    end

    test "formats both insights and operator_results" do
      result = %{
        insights: [
          %{confidence: :high, summary: "Critical issue found"}
        ],
        operator_results: [
          %{
            skill: MyApp.Skills.Process,
            state: :running,
            notifications: [],
            snapshots: []
          }
        ]
      }

      output = Summarizer.format_analysis_data(result)

      assert String.contains?(output, "## Insights")
      assert String.contains?(output, "[high] Critical issue found")
      assert String.contains?(output, "## Operator Results")
      assert String.contains?(output, "### Process (running)")
    end

    test "handles insights without optional fields" do
      result = %{
        insights: [
          %{summary: "Basic insight"}
        ]
      }

      output = Summarizer.format_analysis_data(result)

      assert String.contains?(output, "[unknown] Basic insight")
      refute String.contains?(output, "Hypothesis:")
    end

    test "handles operator_results without notifications or snapshots" do
      result = %{
        operator_results: [
          %{
            skill: MyApp.Skills.Network,
            state: :idle
          }
        ]
      }

      output = Summarizer.format_analysis_data(result)

      assert String.contains?(output, "### Network (idle)")
    end
  end
end

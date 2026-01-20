defmodule BeamlensWeb.DashboardLiveTest do
  use ExUnit.Case
  alias BeamlensWeb.DashboardLive
  alias BeamlensWeb.ChatMessage

  # Note: mount/3 requires the full Beamlens application to be running,
  # so we test the individual event handlers instead.

  describe "handle_event new_conversation" do
    test "resets messages and context" do
      socket =
        build_socket()
        |> assign(:messages, [ChatMessage.user("test")])
        |> assign(:input_text, "some text")
        |> assign(:current_question, "a question")
        |> assign(:analysis_result, %{insights: []})
        |> assign(:chat_context, Puck.Context.add_message(Puck.Context.new(), :user, "test"))

      {:noreply, new_socket} = DashboardLive.handle_event("new_conversation", %{}, socket)

      assert new_socket.assigns.messages == []
      assert new_socket.assigns.input_text == ""
      assert new_socket.assigns.current_question == nil
      assert new_socket.assigns.analysis_result == nil
      assert new_socket.assigns.chat_context.messages == []
    end
  end

  describe "handle_event send_message" do
    test "ignores empty messages" do
      socket =
        build_socket()
        |> assign(:analysis_running, false)

      {:noreply, new_socket} =
        DashboardLive.handle_event("send_message", %{"message" => ""}, socket)

      assert new_socket.assigns.messages == []
    end

    test "ignores whitespace-only messages" do
      socket =
        build_socket()
        |> assign(:analysis_running, false)

      {:noreply, new_socket} =
        DashboardLive.handle_event("send_message", %{"message" => "   "}, socket)

      assert new_socket.assigns.messages == []
    end

    test "ignores messages when analysis is running" do
      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_event("send_message", %{"message" => "test"}, socket)

      assert new_socket.assigns.messages == []
    end
  end

  describe "handle_event stop_analysis" do
    test "adds stopped message when no task running" do
      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, nil)
        |> assign(:messages, [])

      {:noreply, new_socket} = DashboardLive.handle_event("stop_analysis", %{}, socket)

      assert new_socket.assigns.analysis_running == false
      assert length(new_socket.assigns.messages) == 1

      [message] = new_socket.assigns.messages
      assert message.role == :coordinator
      assert message.content == "Stopped by user."
      assert message.message_type == :text
    end
  end

  describe "handle_event clear_chat" do
    test "clears all messages" do
      socket =
        build_socket()
        |> assign(:messages, [ChatMessage.user("test1"), ChatMessage.coordinator("test2")])

      {:noreply, new_socket} = DashboardLive.handle_event("clear_chat", %{}, socket)

      assert new_socket.assigns.messages == []
    end
  end

  describe "handle_event update_input" do
    test "updates input_text assign" do
      socket =
        build_socket()
        |> assign(:input_text, "")

      {:noreply, new_socket} =
        DashboardLive.handle_event("update_input", %{"message" => "new text"}, socket)

      assert new_socket.assigns.input_text == "new text"
    end
  end

  describe "handle_info {:DOWN, ...}" do
    test "ignores normal exits" do
      pid = spawn(fn -> :ok end)
      ref = Process.monitor(pid)

      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, pid)
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_info({:DOWN, ref, :process, pid, :normal}, socket)

      assert new_socket.assigns.analysis_running == true
      assert new_socket.assigns.messages == []
    end

    test "handles analysis task crashes" do
      pid = spawn(fn -> :ok end)
      ref = Process.monitor(pid)

      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, pid)
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_info({:DOWN, ref, :process, pid, :killed}, socket)

      assert new_socket.assigns.analysis_running == false
      assert new_socket.assigns.analysis_task_pid == nil
      assert length(new_socket.assigns.messages) == 1

      [message] = new_socket.assigns.messages
      assert message.role == :coordinator
      assert message.message_type == :error
      assert String.contains?(message.content, "Analysis failed")
    end

    test "handles summarization task crashes" do
      pid = spawn(fn -> :ok end)
      ref = Process.monitor(pid)

      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, nil)
        |> assign(:summarization_task_pid, pid)
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_info({:DOWN, ref, :process, pid, {:error, :timeout}}, socket)

      assert new_socket.assigns.analysis_running == false
      assert new_socket.assigns.summarization_task_pid == nil
      assert length(new_socket.assigns.messages) == 1

      [message] = new_socket.assigns.messages
      assert message.role == :coordinator
      assert message.message_type == :error
      assert String.contains?(message.content, "Summarization failed")
    end

    test "ignores DOWN for unknown pids" do
      unknown_pid = spawn(fn -> :ok end)
      ref = Process.monitor(unknown_pid)

      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, spawn(fn -> :ok end))
        |> assign(:summarization_task_pid, nil)
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_info({:DOWN, ref, :process, unknown_pid, :killed}, socket)

      assert new_socket.assigns.analysis_running == true
      assert new_socket.assigns.messages == []
    end
  end

  describe "handle_info {:analysis_complete, {:error, reason}, user_question}" do
    test "adds error message for chat analysis failure" do
      socket =
        build_socket()
        |> assign(:analysis_running, true)
        |> assign(:analysis_task_pid, spawn(fn -> :ok end))
        |> assign(:current_question, "test question")
        |> assign(:messages, [])

      {:noreply, new_socket} =
        DashboardLive.handle_info(
          {:analysis_complete, {:error, "Connection timeout"}, "test question"},
          socket
        )

      assert new_socket.assigns.analysis_running == false
      assert new_socket.assigns.analysis_task_pid == nil
      assert new_socket.assigns.current_question == nil
      assert length(new_socket.assigns.messages) == 1

      [message] = new_socket.assigns.messages
      assert message.role == :coordinator
      assert message.message_type == :error
      assert message.content == "Connection timeout"
    end
  end

  # Note: {:summary_complete, {:error, reason}, result} handler calls refresh_data
  # which requires the Beamlens application to be running. The error handling path
  # is validated by testing the message construction in build_coordinator_messages.

  defp build_socket do
    assigns = %{
      __changed__: %{},
      flash: %{},
      messages: [],
      input_text: "",
      current_question: nil,
      chat_context: Puck.Context.new(),
      analysis_running: false,
      analysis_result: nil,
      analysis_task_pid: nil,
      summarization_task_pid: nil,
      selected_skills: [],
      available_skills: [],
      selected_node: Node.self(),
      trigger_context: "",
      operators: [],
      notifications: [],
      insights: [],
      coordinator_status: %{},
      events_paused: false,
      events: [],
      filtered_events: [],
      event_sources: [],
      notification_counts: %{total: 0, unread: 0, acknowledged: 0, resolved: 0},
      event_type_filter: nil,
      selected_source: :trigger,
      selected_event_id: nil,
      sidebar_open: false,
      settings_open: false,
      last_updated: DateTime.utc_now(),
      available_nodes: [Node.self()]
    }

    struct!(Phoenix.LiveView.Socket, assigns: assigns)
  end

  defp assign(socket, key, value) do
    %{socket | assigns: Map.put(socket.assigns, key, value)}
  end
end

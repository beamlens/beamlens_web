defmodule BeamlensWeb.ChatMessageTest do
  use ExUnit.Case
  alias BeamlensWeb.ChatMessage

  describe "struct definition" do
    test "enforces required keys" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn ->
        struct!(ChatMessage, %{})
      end
    end

    test "creates struct with all required fields" do
      msg = %ChatMessage{
        id: "msg-123",
        role: :user,
        content: "Hello",
        timestamp: DateTime.utc_now()
      }

      assert msg.id == "msg-123"
      assert msg.role == :user
      assert msg.content == "Hello"
      assert msg.message_type == nil
    end
  end

  describe "user/2" do
    test "creates user message with content" do
      msg = ChatMessage.user("Test message")

      assert msg.role == :user
      assert msg.content == "Test message"
      assert String.starts_with?(msg.id, "msg-")
      assert %DateTime{} = msg.timestamp
    end

    test "accepts optional skills_used" do
      skills = [MyApp.Skills.Memory, MyApp.Skills.Process]
      msg = ChatMessage.user("Test", skills_used: skills)

      assert msg.skills_used == skills
    end

    test "accepts custom id and timestamp" do
      timestamp = ~U[2024-01-15 10:00:00Z]
      msg = ChatMessage.user("Test", id: "custom-id", timestamp: timestamp)

      assert msg.id == "custom-id"
      assert msg.timestamp == timestamp
    end
  end

  describe "coordinator/2" do
    test "creates coordinator message with content" do
      msg = ChatMessage.coordinator("Analysis complete")

      assert msg.role == :coordinator
      assert msg.content == "Analysis complete"
      assert msg.message_type == :text
      assert String.starts_with?(msg.id, "msg-")
    end

    test "accepts message_type option" do
      msg = ChatMessage.coordinator("Error occurred", message_type: :error)

      assert msg.message_type == :error
    end

    test "accepts rendered_html option" do
      html = "<p>Formatted content</p>"
      msg = ChatMessage.coordinator("Content", rendered_html: html)

      assert msg.rendered_html == html
    end

    test "accepts insights option" do
      insights = [%{summary: "Found issue", confidence: :high}]
      msg = ChatMessage.coordinator("Found insights", message_type: :insights, insights: insights)

      assert msg.message_type == :insights
      assert msg.insights == insights
    end

    test "accepts custom id and timestamp" do
      timestamp = ~U[2024-01-15 10:00:00Z]
      msg = ChatMessage.coordinator("Test", id: "coord-123", timestamp: timestamp)

      assert msg.id == "coord-123"
      assert msg.timestamp == timestamp
    end
  end

  describe "type specification" do
    test "user message has expected field types" do
      msg = ChatMessage.user("Hello", skills_used: [:skill1])

      assert is_binary(msg.id)
      assert msg.role == :user
      assert is_binary(msg.content)
      assert %DateTime{} = msg.timestamp
      assert is_list(msg.skills_used)
      assert is_nil(msg.message_type)
      assert is_nil(msg.rendered_html)
      assert is_nil(msg.insights)
    end

    test "coordinator message has expected field types" do
      msg =
        ChatMessage.coordinator("Hello",
          message_type: :text,
          rendered_html: "<p>Hello</p>",
          insights: []
        )

      assert is_binary(msg.id)
      assert msg.role == :coordinator
      assert is_binary(msg.content)
      assert %DateTime{} = msg.timestamp
      assert msg.message_type == :text
      assert is_binary(msg.rendered_html)
      assert is_list(msg.insights)
      assert is_nil(msg.skills_used)
    end
  end
end

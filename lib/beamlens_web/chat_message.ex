defmodule BeamlensWeb.ChatMessage do
  @moduledoc """
  Represents a chat message in the dashboard conversation.

  This struct is used to store messages in the chat interface between the user
  and the BeamLens coordinator. Messages can be from the user (`:user`) or
  from the coordinator (`:coordinator`).

  ## Fields

    * `:id` - Unique identifier for the message (required)
    * `:role` - Either `:user` or `:coordinator` (required)
    * `:content` - The text content of the message (required)
    * `:timestamp` - When the message was created (required)
    * `:message_type` - Type of coordinator message: `:text`, `:insights`, or `:error`
    * `:rendered_html` - Pre-rendered HTML for markdown content
    * `:insights` - List of insights when message_type is `:insights`
    * `:skills_used` - List of skill modules used (for user messages)
  """

  @enforce_keys [:id, :role, :content, :timestamp]
  defstruct [
    :id,
    :role,
    :content,
    :timestamp,
    :message_type,
    :rendered_html,
    :insights,
    :skills_used
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          role: :user | :coordinator,
          content: String.t(),
          timestamp: DateTime.t(),
          message_type: :text | :insights | :error | nil,
          rendered_html: String.t() | nil,
          insights: list() | nil,
          skills_used: list() | nil
        }

  @doc """
  Creates a new user message.
  """
  def user(content, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id, generate_id()),
      role: :user,
      content: content,
      timestamp: Keyword.get(opts, :timestamp, DateTime.utc_now()),
      skills_used: Keyword.get(opts, :skills_used)
    }
  end

  @doc """
  Creates a new coordinator message.
  """
  def coordinator(content, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id, generate_id()),
      role: :coordinator,
      content: content,
      timestamp: Keyword.get(opts, :timestamp, DateTime.utc_now()),
      message_type: Keyword.get(opts, :message_type, :text),
      rendered_html: Keyword.get(opts, :rendered_html),
      insights: Keyword.get(opts, :insights)
    }
  end

  defp generate_id do
    "msg-" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end

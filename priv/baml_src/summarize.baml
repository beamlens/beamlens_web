// Summarization function for BeamlensWeb dashboard chat

function SummarizeAnalysis(user_question: string, analysis_data: string, conversation_history: string) -> string {
  client Default
  prompt #"
    You are a helpful assistant analyzing BEAM/Elixir systems. You have access to the conversation history below.

    {% if conversation_history != "" %}
    ## Previous Conversation
    {{ conversation_history }}
    {% endif %}

    ## Current Question
    The user asked: "{{ user_question }}"

    ## Analysis Results
    Here are the latest analysis results from inspecting the system:

    {{ analysis_data }}

    Please provide a clear, conversational summary of these findings.
    - Consider the conversation context when answering
    - If the user references something from earlier, use the conversation history to respond appropriately
    - Focus on what's most relevant to the user's question
    - If there are warnings or issues, explain them in plain language
    - Include specific numbers/metrics when relevant
    - Keep it concise but informative
    - Use markdown formatting for readability
  "#
}

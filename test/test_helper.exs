# Ensure Phoenix is started for tests
Application.ensure_all_started(:phoenix)

# ExUnit configuration - include support files
ExUnit.start(test_load_filters: [~r/test\/.*\.exs$/])

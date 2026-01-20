# Ensure Phoenix is started for tests
Application.ensure_all_started(:phoenix)

# Start the stores manually since BeamlensWeb is a library
# that doesn't auto-start (no mod callback in application/0)
{:ok, _} = BeamlensWeb.NotificationStore.start_link([])
{:ok, _} = BeamlensWeb.InsightStore.start_link([])
{:ok, _} = BeamlensWeb.EventStore.start_link([])

# ExUnit configuration
ExUnit.start()

defmodule BeamlensWeb.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reset at the beginning of every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import BeamlensWeb.DataCase
    end
  end

  setup _tags do
    :ok
  end
end

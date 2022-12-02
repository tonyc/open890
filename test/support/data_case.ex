defmodule Open890.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Open890.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  require Logger

  using do
    quote do
      import Open890.DataCase
    end
  end

  setup do
    {:ok, dets_table} = Open890.RadioConnectionRepo.init()

    on_exit(fn ->
      IO.puts("Stopping dets and removing database: #{dets_table}")
      :dets.stop()
      File.rm!(dets_table |> to_string())
    end)

    :ok
  end
end

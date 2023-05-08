defmodule Open890.UserMarker do
  defstruct id: nil, freq: nil

  alias Uniq.UUID

  def create(freq) do
    %__MODULE__{id: UUID.uuid7(), freq: freq}
  end
end

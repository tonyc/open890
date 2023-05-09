defmodule Open890.UserMarker do
  defstruct id: nil, freq: nil, color: :green

  alias Uniq.UUID

  def create(freq) do
    %__MODULE__{id: UUID.uuid7(), freq: freq, color: :green}
  end

  def red(%__MODULE__{} = m) do
    %{m | color: :red}
  end

  def green(%__MODULE__{} = m) do
    %{m | color: :green}
  end

  def blue(%__MODULE__{} = m) do
    %{m | color: :blue}
  end
end

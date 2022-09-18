defmodule Open890.MemoryChannels do
  alias Open890.MemoryChannel

  defstruct channels: nil

  def new do
    %__MODULE__{
      channels: Map.new()
    }
  end

  def save(%__MODULE__{} = mod, %MemoryChannel{channel_number: channel_number} = memory_channel) do
    mod.channels
    |> Map.put(channel_number, memory_channel)
  end

  def get_by_channel_number(%__MODULE__{} = mod, channel_number) do
    mod.channels
    |> Map.get(channel_number)
  end
end

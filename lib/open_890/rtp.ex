defmodule Open890.RTP do
  defstruct version: nil,
            padding: nil,
            extension: nil,
            csrc_count: nil,
            marker: nil,
            payload_type: nil,
            sequence_number: nil,
            timestamp: nil,
            ssrc: nil,
            payload: nil

  @type t :: %__MODULE__{
          version: 0 | 1 | 2 | 3,
          padding: 0 | 1,
          extension: 0 | 1,
          csrc_count: non_neg_integer,
          marker: 0 | 1,
          payload_type: non_neg_integer,
          sequence_number: non_neg_integer,
          timestamp: non_neg_integer,
          ssrc: non_neg_integer,
          payload: String.t()
        }

  def parse_packet(data) do
    with {:ok, struct} <- new(data) do
      {:ok, struct}
    else
      {:error, error} ->
        {:error, {error, data}}
    end
  end

  def new(data) do
    with <<
           version::size(2),
           padding::size(1),
           extension::size(1),
           csrc_count::size(4),
           marker::size(1),
           payload_type::size(7),
           sequence_number::size(16),
           timestamp::size(32),
           ssrc::size(32),
           payload::binary
         >> <- data do
      udp = %__MODULE__{
        version: version,
        padding: padding,
        extension: extension,
        csrc_count: csrc_count,
        marker: marker,
        payload_type: payload_type,
        sequence_number: sequence_number,
        timestamp: timestamp,
        ssrc: ssrc,
        payload: payload
      }

      {:ok, udp}
    else
      _ ->
        {:error, :parse_error}
    end
  end
end

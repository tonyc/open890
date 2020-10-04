defmodule Open890 do
  @moduledoc """
  Open890 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def ch_up, do: "CH0" |> cmd()
  def ch_down, do: "CH1" |> cmd()

  def radio_up(args \\ "04") when is_binary(args), do: "UP#{args}" |> cmd()
  def radio_down(args \\ "04") when is_binary(args), do: "DN#{args}" |> cmd()

  def freq_change(:up) do
    ("FC0" <> freq_change_step())
    |> cmd()
  end

  def freq_change(:down) do
    ("FC1" <> freq_change_step())
    |> cmd()
  end

  def vfo_a_b_swap, do: "EC" |> cmd()

  def get_vfo_a_freq do
    "FA" |> cmd()
  end

  def get_vfo_b_freq do
    "FB" |> cmd()
  end

  # TODO: Make this configurable
  defp freq_change_step, do: "4"

  def cmd(cmd) when is_binary(cmd) do
    Open890.TCPClient.cmd(cmd)
  end

end

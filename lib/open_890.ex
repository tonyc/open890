defmodule Open890 do
  @moduledoc """
  Open890 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def ch_up, do: "CH0" |> send_command()
  def ch_down, do: "CH1" |> send_command()

  def radio_up(args \\ "04") when is_binary(args), do: "UP#{args}" |> send_command()
  def radio_down(args \\ "04") when is_binary(args), do: "DN#{args}" |> send_command()

  def send_command(cmd) when is_binary(cmd) do
    Open890.TCPClient.cmd(cmd)
  end

end

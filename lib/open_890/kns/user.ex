defmodule Open890.KNS.User do
  defstruct username: nil, password: nil, is_admin: false

  alias __MODULE__

  def build, do: %User{username: "", password: "", is_admin: false}

  def username(%User{} = user, username) do
    %{user | username: username}
  end

  def password(%User{} = user, password) do
    %{user | password: password}
  end

  def is_admin(%User{} = user, is_admin \\ true) do
    %{user | is_admin: is_admin}
  end

  def to_login(%User{} = user) do
    user |> make_login()
  end

  defp make_login(%User{} = user) do
    [user_length, pass_length] =
      [user.username, user.password]
      |> Enum.map(fn str ->
        str
        |> String.length()
        |> to_string()
        |> String.pad_leading(2, "0")
      end)

    admin_code(user) <> user_length <> pass_length <> user.username <> user.password
  end

  defp admin_code(%User{is_admin: true} = _user), do: "0"
  defp admin_code(%User{} = _user), do: "1"
end

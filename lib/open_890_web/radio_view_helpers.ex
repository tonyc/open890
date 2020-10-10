defmodule Open890Web.RadioViewHelpers do

  def selected_theme?(theme, name) do
    if theme == name, do: "selected"
  end

end

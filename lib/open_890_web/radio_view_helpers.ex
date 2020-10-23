defmodule Open890Web.RadioViewHelpers do
  import Phoenix.HTML.Tag

  def selected_theme?(theme, name) do
    if theme == name, do: "selected"
  end

  def cmd_button(name, cmd) when is_binary(name) and is_binary(cmd) do
    content_tag(:button, name, phx_click: "cmd", phx_value_cmd: cmd)
  end

  def format_band_scope_mode(mode) do
    mode
    |> case do
      :auto_scroll -> "Auto-Scroll"
      :fixed -> "Fixed"
      :center -> "Center"
      _ -> ""
    end
  end

end

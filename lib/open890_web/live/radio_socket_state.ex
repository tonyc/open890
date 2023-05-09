defmodule Open890Web.Live.RadioSocketState do
  alias Open890.RadioState

  @init_socket [
    {:active_tab, "txrx"},
    {:audio_scope_data, []},
    {:band_scope_data, []},
    {:connection_state, :stopped},
    {:connection_state, nil},
    {:debug, false},
    {:display_band_selector, false},
    {:left_panel_open, true},
    {:keyboard_entry_state, :normal},
    {:keyboard_entry_timer, nil},
    {:markers, []},
    {:projected_active_receiver_location, ""},
    {:radio_connection, nil},
    {:radio_state, %RadioState{}},
    {:spectrum_scale, 1.0},
    {:theme, "kenwood"},
    {:waterfall_draw_interval, 1},
    {:__ui_macros, %{}}
  ]

  def initial_state do
    @init_socket |> Enum.into(%{})
  end
end

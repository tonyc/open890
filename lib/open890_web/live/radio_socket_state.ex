defmodule Open890Web.Live.RadioSocketState do
  alias Open890.{AntennaState, BandRegisterState, FilterState, NoiseBlankState, NotchState, TransverterState}

  alias Open890.RadioState

  @init_socket [
    {:radio_state, %RadioState{}},
    {:display_band_selector, false},
    {:radio_connection, nil},
    {:connection_state, nil},
    {:debug, false},
    {:projected_active_receiver_location, ""},
    {:theme, "kenwood"},
    {:waterfall_draw_interval, 1},
    {:spectrum_scale, 1.0},
    {:connection_state, :stopped},
    {:__ui_macros, %{}}
  ]

  def initial_state do
    @init_socket |> Enum.into(%{})
  end
end

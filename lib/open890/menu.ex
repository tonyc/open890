defmodule Open890.Menu do
  @top_menu_id 136

  @menu %{
    136 => %{
      items: [
        %{
          num: "0",
          title: "Basic Configurations",
          info: "APO, Display, Meter, PF Keys, Touchscreen",
          menu_id: 137
        },
        %{
          num: "1",
          title: "Audio Performance",
          info: "Volume, Voice Guidance, Headphones",
          menu_id: 138
        },
        %{
          num: "2",
          title: "Decoding & Encoding",
          info: "FSK, PSK, Data Format",
          menu_id: 139
        },
        %{
          num: "3",
          title: "Controls Configurations",
          info: "Frequency Step Size, Miscellaneous",
          menu_id: 140
        },
        %{
          num: "4",
          title: "Memory Channels & Scan",
          info: "Slow Scan, Quick Memory Channel",
          menu_id: 141
        },
        %{
          num: "5",
          title: "CW Configurations",
          info: "CW Keying, Repeat Interval, Miscellaneous",
          menu_id: 142,
        },
        %{
          num: "6",
          title: "TX/RX Filters & Misc",
          info: "IF Fil, HC/LC, Rec. Time, TX Inhibit",
          menu_id: 143,
        },
        %{
          num: "7",
          title: "Rear Connectors",
          info: "Audio Levels, Baud Rate, DX PacketCluster, EXT SP",
          menu_id: 144
        },
        %{
          num: "8",
          title: "Bandscope",
          info: "Hold Time, Scale, Edge Frequency",
          menu_id: 145
        },
        %{
          num: "9",
          title: "USB Keyboard",
          info: "USB Keyboard Configuration",
          menu_id: 146
        }
      ]
    }
  }

  def top_menu_id(), do: @top_menu_id

  def get(id) do
    @menu
    |> Map.get(id)
    |> case do
      nil -> {:error, {:unknown_menu, id}}
      menu -> {:ok, menu}
    end
  end

end

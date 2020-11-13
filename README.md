# Open890

![Elixir CI status](https://github.com/tonyc/open890/workflows/.github/workflows/elixir-ci.yml/badge.svg)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Config

This app needs the following ENV variables set:

  * RADIO_IP_ADDRESS - IP address of the TS-890
  * RADIO_USERNAME - The KNS username
  * RADIO_PASSWORD - The KNS password
  * RADIO_USER_IS_ADMIN (true/false) - Whether the KNS user is an admin

## Forwarding UDP packets from Windows 10 to WSL2:

Download sudppipe.exe from http://www.softsea.com/review/Simple-UDP-Proxy-Pipe.html, then:


  * Figure out the IPV4 address inside WSL:

      `ifconfig -a | grep inet | grep -v inet6 | grep -v 127 | awk '{print $2}'`

  * Run sudppipe:

      `sudppipe.exe -x -b 0.0.0.0 172.18.241.58 60001 60001`

## Misc

### Undocumented commands
  * MD (MD1, MD2 etc)
  * IF - (IF frequency?) - when changing from VFO 7mhz to memory 29 mhz 
    * [warn] Unhandled message: "IF00026975000      000000051052000000"
  * MC - when changing memory channels - coordinates with adjusting the multi/ch up and down
    * [warn] Unhandled message: "MC 51"

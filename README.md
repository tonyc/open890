# open890

![Elixir CI status](https://github.com/tonyc/open890/workflows/Test/badge.svg)

open890 is a web-based UI for the Kenwood TS-890S amateur radio, and features good usability, 
clean design, and high-speed bandscope/audio scope displays, among other features not available
either on the radio itself, or in the ARCP remote control software.

It is currently only designed to interface with the TS890 via a LAN (or wifi) connection, and not
a USB (or serial) connection.

## Installation from source

You will need Elixir (and thus, erlang) and NodeJS installed, particularly if you are either
developing features for open890, or using a non-binary (e.g. source) release.

Using a tool like [asdf](https://asdf-vm.com/#/core-manage-asdf) is recommended
to manage the various versions of the development dependencies.

### Using asdf

  * Install asdf
  * Install erlang, elixir and nodeJS plugins

        asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
        asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
        asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

  * Install the specific versions listed in .tool-versions:

        asdf install erlang 22.3.4.6
        asdf install elixir 1.10.4-otp-22
        asdf install nodejs 12.18.3

  * Once everything has installed, you should be able to run `elixir --version` and see the correct version listed.


## Binary releases

Binary releases are available from [releases](https://github.com/tonyc/open890/releases/).
They currently are only supported to run on 64-bit Ubuntu 20.04, although other modern Linux releases may work (or not).

The binary is a self-contained ELF executable that expands itself into `~/.cache/bakeware`

After downloading:

        chmod u+x open890
        ./open890

If you encounter an error related to shared libraries, etc, they _may_ be solved by installing the correct version,
although the correct packages may not be available in your OS distribution's package manager. 

If all else fails, install from source.

## Config

This app needs the following variables set in your ENV. These will eventually be moved into a UI.

  * `RADIO_IP_ADDRESS` - IP address of the TS-890
  * `RADIO_USERNAME` - The KNS username
  * `RADIO_PASSWORD` - The KNS password
  * `RADIO_USER_IS_ADMIN` (true/false) - Whether the KNS user is an admin

You will need to use a wrapper shell script, or do something like:

        export RADIO_IP_ADDRESS=w.x.y.z
        export RADIO_USERNAME=whatever
        # etc..
        
And then start your server.

## To start your server:

  * Install dependencies with `mix deps.get`. First-time users may need to answer `Y` to a couple prompts
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


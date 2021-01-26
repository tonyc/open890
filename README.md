# open890

![Elixir CI status](https://github.com/tonyc/open890/workflows/Test/badge.svg)

open890 is a web-based UI for the Kenwood TS-890S amateur radio, and features good usability, 
clean design, and high-speed bandscope/audio scope displays, among other features not available
either on the radio itself, or in the ARCP remote control software.

It is currently only designed to interface with the TS-890 via a LAN (or wifi) connection, and not
a USB/serial connection. It may work with the TS-990, as the command set is very similar, but is
currently untested.

## Installation from source

These instructions assume a basic knowledge of Linux/Unix and command-line tools.

open890 is currently supported under Linux, or Linux-like operating systems. You can also run it
in Windows 10 if you have [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) installed - much of this project was written under WSL.

You will need Elixir (and thus, Erlang) and NodeJS installed, particularly if you are either
developing features for open890, or using a non-binary (e.g. source) release.

Using a tool like [asdf](https://asdf-vm.com/#/core-manage-asdf) is recommended
to manage the various versions of the development dependencies.

### Using asdf

  * Install asdf
  * Install erlang, elixir and nodeJS plugins

        asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
        asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
        asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

  * At this point, Raspberry Pi users may need to install the following packages:
  
        sudo apt -y install autoconf libssl-dev libncurses5-dev
  
  * Install the specific versions listed in the `.tool-versions` file:

        asdf install erlang 22.3.4.6
        asdf install elixir 1.10.4-otp-22
        asdf install nodejs 12.18.3

  * You may see scary-looking messages during the Erlang install that says something like "fop is missing" or "documentation cannot be built" - this is OK.       
  * Once everything has installed, you should be able to run `elixir --version` and also `npm --version`
  * Clone this repository
  
  * Continue from [Config](#config)


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

The following variables must be set in your ENV. These will eventually be moved into a UI.

  * `RADIO_IP_ADDRESS` - IP address of the TS-890
  * `RADIO_USERNAME` - The KNS username
  * `RADIO_PASSWORD` - The KNS password
  * `RADIO_USER_IS_ADMIN` (true/false) - Whether the KNS user is an admin

You will need to use a wrapper shell script, or do something like:

    export RADIO_IP_ADDRESS=w.x.y.z
    export RADIO_USERNAME=whatever
    # etc..
        
## To start your server:

  * Install dependencies with `mix deps.get`. First-time users may need to answer `Y` to a couple prompts
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`http://localhost:4000`](http://localhost:4000) from your browser.

## Stopping your server

Type `^c^c` (aka: ctrl-c twice)

## Getting Help

If you encounter a bug, please [open a discussion](https://github.com/tonyc/open890/discussions/new). Please do not directly email me for technical support!

## Contributing

* [Start a discussion](https://github.com/tonyc/open890/discussions/new) so we can discuss your idea
* Fork this repository
* Make your changes in a branch in your own repo
* Open a pull request!

## Legal mumbo-jumbo

This project is licensed under the MIT license. Please see [MIT-LICENSE](MIT-LICENSE) for more details.

All product names, logos, brands, trademarks and registered trademarks are property of their respective owners. All company, product and service names used in this software are for identification purposes only.


# open890

![Elixir CI status](https://github.com/tonyc/open890/workflows/Test/badge.svg)

open890 is a web-based UI for the Kenwood TS-890S amateur radio, and features good usability, 
clean design, and high-speed bandscope/audio scope displays, among other features not available
either on the radio itself, or in the ARCP remote control software.

It is currently only designed to interface with the TS-890 via a LAN (or wifi) connection, and not
a USB/serial connection. It may work with the TS-990, as the command set is very similar, but is
currently untested.

![open890 screenshot](docs/screenshot.png)

## Installation from source

See [Installing From Source](https://github.com/tonyc/open890/wiki/Installing-From-Source)


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

## Getting Help

If you encounter a bug, please [open a discussion](https://github.com/tonyc/open890/discussions). Please do not directly email me for technical support!

## Contributing

* [Start a discussion](https://github.com/tonyc/open890/discussions) so we can discuss your idea
* Fork this repository
* Make your changes in a branch in your own repo
* Open a pull request!

## Legal mumbo-jumbo

This project is licensed under the MIT license. Please see [MIT-LICENSE](MIT-LICENSE) for more details.

All product names, logos, brands, trademarks and registered trademarks are property of their respective owners. All company, product and service names used in this software are for identification purposes only.


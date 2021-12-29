# open890 Changelog

## Unreleased
* Implemented correct shift/width display for bandscope passband polygon

## 0.6.1 - 2021-12-28
* Fixes a display crash related to entering SSB-DATA mode and default settings for menu items 6-11/6-12.
* Fixes incorrectly-displayed frequency in browser tab title
* [Dev] Added a Makefile, and updated dev instructions on wiki. Running 'make' should more or less result in a reproducible build, including installing dependencies.


## 0.6.0 - 2021-12-05
* Added SPLIT button, TX frequency display on spectrum, offscreen indicator
* Rearranged UI considerably. Added collapsible side panel for buttons, arranged buttons into tabs
* [Dev] Removed node, npm, webpack and node-sass as development dependencies in favor of esbuild and dart-sass.
* Added SQL control
* Added NR, NB, BC, NCH control buttons.
* Added the ability to pop out separate bandscope, audioscope, and meter displays.
* Fixed white UI background on radio/bandscope screens.

## 0.5.1 - 2021-11-22
* Fixed non-functional macro buttons

## 0.5 - 2021-11-02

* Added NR, NB, BC, NOTCH indicator row to UI
* Added notch position marker to audio scope in CW mode
* Added power level, mic gain, key speed, key delay, AGC status in top bar
* Added start/stop connection button in top bar.
* Added band stack register display
* Display connection status and error messages in top bar, including "Connection already in use" and "Incorrect username/password"
* Display a useful startup banner in the console.
* Added TX TUNE indicator
* Added experimental keyboard shortcuts: 's' to shift bandscope, ] and [ to MULTI/CH up/down
* Swapped the location of the VFO A/B and A=B buttons
* Changed spectrum scope gradient fill behavior to much more closely resembles the spectrum fill on the TS-890.
* Fixed multiple connections broadcasting to the same topic. All connection-specific data is now only broadcast to the bandscope for that connection.
* Fixed a bug where the connection wasn't startable from the bandscope on incorrect username/password.
* Fixed audio scope filter edges shifting the wrong direction in CW mode (#75)
* Fixed incorrectly displayed audio scope filter edges in CW mode when the filter width is above 700 Hz
* [Dev] Upgraded to Elixir 1.12, Erlang/OTP 23.3.4.6, Phoenix 1.16-rc.0
* [Dev] Removed various unused dependencies, replaced UUID library with Uniq.UUID
* [Dev] Added an experimental Dockerfile

## 0.0.9 - 2021-08-14

* Implemented center mode's "straight waterfall" functionality.
* Added ANT1/2, RX ANT, ANT OUT, and DRV indicators above s-meter
* Mousewheel (w/o shift held) while hovered over bandscope performs MULTI/CH
* Increased log level to :error for TCP socket connection errors

## 0.0.8 - 2021-06-27

* Track transverter state & offset, apply offset to VFO display (#81)
* Allow the configuration of the TCP port on connections.
* Fix new connections that had auto-start off being incorrectly started.
* Altered debug messages to use "UP" and "DN" to denote traffic to and from the radio.
* Fixed initial band scope limits for auto-scroll mode

## 0.0.7 - 2021-06-04

* Allow top-level KNS admin users to connect
* Fixed connection auto-starting on app startup.
* Auto-start newly created connections when auto-start is checked.

## 0.0.6 - 2021-04-11

* Added config/example.config.toml to binary releases to make it apparent how to configure macro buttons.

## 0.0.5 - 2021-04-10

* Adds spectrum Y-axis scaling
* Adds adds waterfall speed/scroll control, independent from radio's setting or data speed setting.
* Adds user-defined macro buttons. See config/example.config.toml for details.
* Adds band/mode selector by clicking the main VFO frequency
* Adds PRE/ATT and M/V controls
* Adds audio filter details (selected IF FIL, width/shift, RFT width)
* Correctly draw audio scope filter edges for LSB/USB/FM/AM
* Adds auto-start option for connections
* Reworked bandscope buttons to allow up/down control
* Vertical gridlines correctly track in center scope mode
* Changed AF/RF gain controls to sliders

## 0.0.4 - 2021-03-13

* Removes an unnecessary service that was included in binary builds.

## 0.0.3

* Initial release


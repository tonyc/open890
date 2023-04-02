# open890 Changelog

## Unreleased
* Fixed incorrect passband polygon in certain cases when in memory mode. (#105)
* Fixed inconsistent mousewheel steps when overing over spectrum vs. waterfall.
* Made the MACRO button section two columns.
* Radio screen now redirects to connection list when it can't find the requested connection ID.
* Resolved an issue where the audio scope filter edges disappear when stopping and restarting a connection (#105)
* Updated docker-compose.yml and documentation to forward UDP port 60001, to allow audio streaming when using the Docker image (#108)
* Added Span kHz readout on main bandscope
* Fixed a startup crash related to not knowing the filter width when displaying the audio filter edges.
* Added favicon/browser tab icons (#106)
* Fixed incorrectly-shifted passband polygon for FSK/PSK modes (#97)
* [Dev] Removed dependency on 'timex', 'poison', 'elixir_math', 'ecto', 'phoenix_live_dashboard' packages.
* [Dev] Upgraded to latest released version of Phoenix 1.16 to prepare for further update
* [Dev] Tools update: new versions of Elixir, Erlang, and NodeJS required to build
* Implemented fixed scope mode vertical bandscope grid lines.
* [Dev] Cleaned up several compilation warnings
* [Dev] Converted deprecated ~e{} Phoenix Liveview sigil to ~H function components
* Added experimental MacOS binary build support

## 1.0.3 - 2022-11-25
* Fixed error on the pop-out standalone bandscope.

## 1.0.2 - 2022-11-24
* Fixed 12m/24MHz band button using incorrect command.

## 1.0.1 - 2022-11-23
* Fixed broken band selector modal dialog

## 1.0.0 - 2022-11-06
1.0.0 represents hundreds of hours over 26 months of part-time work. I hope you enjoy it!

* Implemented memory channel display.
* Added ATU/TUNE/SEND buttons, located on the TX/ANT tab
* Added TX indicator (under VFO) and ATU state indicator at top of display
* Added LOCK button
* Added Busy/TX indicator above RIT offset
* Added the ability to set the hostname that the server binds to. This allows you to access open890 with a specific hostname (e.g. "asus890server"). Set OPEN890_HOST as an environment variable, and then start open890.
* BREAKING CHANGE: Renamed the PORT env var to OPEN890_PORT. This controls the TCP port that open890 binds to.
* Renamed ANT tab to TX/ANT
* Finished FIXED mode RANGE button (#93)
* Refined notch control slider UX, disabled the slider when notch is turned off.
* Relocated the SPLIT button next to RIT/XIT, made the SPLIT button appear yellow when activated.
* Added keyboard shortcut: '\' to perform A/B
* Added keyboard shortcut: '=' to perform A=B
* Changed keyboard shortcut: 's' now toggles SPLIT, 'h' now performs "SHIFT"
* Swapped the position of the A/B and A=B buttons.
* [Dev] Update Dockerfile so it builds and runs (#96)
* [Dev] Added "make build_docker" and "make docker" Makefile targets for building and running the docker image, respectively

## 0.8.0 - 2022-07-30
* UI: Reworked some HTML & CSS for small layout improvements
* [Dev] Updated esbuild config to include --watch flag, allowing CSS to be reloaded on the fly
* Added Basic scope EXPAND functionality.
* Added Antenna controls side tab: ANT1/2, RX ANT, ANT OUT, DRV, XVTR controls
* Finished implementation of notch indicator in SSB mode.
* Added "power" field to Cloudlog integration
* Added HTTP basic authentication. See config/example.config.toml for more information.
* Slightly reworked the "welcome" screen wording to describe where to set up KNS users.

## 0.7.0 - 2022-01-22
* Added audio streaming from the radio. Click the "VOIP Audio" button at the top once the connection is started.
* Added Cloudlog integration - syncs frequency/mode information to a Cloudlog instance.
    * See https://github.com/tonyc/open890/wiki/Cloudlog-Integration for more information
* Added RIT/XIT functionality:
    * Mousewheel while hovered over the offset to adjust, or drag left/right on touch interfaces
* Added notch position slider
* Added mousewheel-based filter adjustments: Wheel for lo/width, shift+wheel for hi/shift.
* Added AGC controls to side panel
* Finished implementation of audio scope filter edges for all modes
* Adjusted buttons as to not keep focus/highlight state after being clicked/tapped
* Adjusted the "TX offscreen" indicator to always show regardless of SPLIT status
* Implemented correct shift/width display for bandscope passband polygon
* [Dev] 'make compile' changed to 'make build'

## 0.6.2 - 2022-01-16
* Fixes a display crash related to AM/FM modes

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


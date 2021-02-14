// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
import { Socket } from "phoenix"
import socket from "./socket"
import "phoenix_html"
import LiveSocket from "phoenix_live_view"

import Hooks from "./hooks"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

import {Interpolate} from "./interpolate"
import {ColorMap} from "./colormap"

window.Interpolate = Interpolate;
window.ColorMap = ColorMap;

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken},
  metadata: {
    click: (evt, el) => {
      return {}
    }
  }
})
liveSocket.connect()

let audioScopeChannel = socket.channel("radio:audio_scope", {})
audioScopeChannel.join()
  .receive("ok", resp => { console.log("joined audio_scope channel", resp) })
  .receive("error", resp => { console.log("error joining audio_scope channel", resp) })


let audioStreamChannel = socket.channel("radio:audio_stream", {})
audioStreamChannel.join()
  .receive("ok", resp => { console.log("Joined audio STREAM successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

let audioCount = 0

audioStreamChannel.on("audio_data", (data) => {
  let buffer = []
  let decoded = atob(data.payload)

  for (var i = 0; i < decoded.length; i++) {
    buffer.push(decoded.charCodeAt(i))
  }

  audioCount += 1

  if (audioCount % 500 == 0) {
    console.log("Received", audioCount, "audio packets")
    console.log("buffer", buffer);
  }
})

$(document).ready(function() {
  if (document.querySelector('#emptyState')) {
    console.log("empty state detected")
    $('#emptyState .appear').transition({
      animation: 'fade',
      duration: 500,
      interval: 500
    })
  } else {
    console.log("no empty state detected")
  }

})


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

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})
liveSocket.connect()


let audioScopeChannel = socket.channel("radio:audio_scope", {})
audioScopeChannel.join()
  .receive("ok", resp => { console.log("Joined audio SCOPE successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

let chart = null;
let count = 0;

if (!document.querySelector('#audioscope')) {
  console.log("No audio scope")
} else {
  console.log("Found audio scope")
  chart = c3.generate({
    bindto: '#audioscope',
    oninit: () => {
      // removes the white background
      document.querySelector('g.c3-chart > g.c3-event-rects').removeAttribute('style')
      // document.querySelector('g.c3-chart > g.c3-event-rects').setAttribute('style', 'fill: darkblue;')
    },
    data: {
      columns: [],
      type: 'line'
    },
    color: {
      pattern: ['#0f0']
    },
    size: {
    },
    point: { show: false },
    grid: {
      x: {
        show: false
      },
      y: {
        show: true
      }
    },
    tooltip: { show: false },
    legend: { show: false },
    axis: {
      x: {
        show: true,
        min: 0,
        max: 212,
        label: false,
        tick: { count: 1 }
      },
      y: {
        padding: { bottom: 0 },
        show: true,
        min: 0,
        max: 50,
        tick: { count: 1 }

      }
    }
  })

  audioScopeChannel.on("scope_data", (data) => {
    count += 1;

    chart.load({
      columns: [
        ["data"].concat(data.payload)
      ],
      transition: { duration: 0 }
    })
  })
}

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
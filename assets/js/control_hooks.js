let ControlHooks = {
  BandScope: {
    mounted() {
      console.log("Bandscope mounted")

      this.handleEvent("band_scope_data", (event) => {
        // console.log("received band_data")
        this.chart.load({
          columns: [
            ["data"].concat(event.payload)
          ]
        })
      })

      this.chart = c3.generate({
        bindto: '#bandScope',
        oninit: () => {
          document.querySelector('#bandScope g.c3-chart > g.c3-event-rects').removeAttribute('style')
          console.log("bandscope chart init()")
        },
        transition: { duration: null },
        data: {
          columns: [],
          type: 'area',
          colors: { 'data': '#00FF00'}
        },
        // color: {
        //   pattern: ['#0f0', '#f0f']
        // },
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
            max: 639,
            label: false,
            tick: { count: 1 },
            padding: 0
          },
          y: {
            padding: 0,
            show: true,
            min: 0,
            max: 140,
            tick: { count: 1 }
          }
        }
      })
    }
  },
  AudioScope: {
    mounted() {
      console.log("Hook: AudioScope: mounted()")

      this.handleEvent("audio_scope_data", (event) => {
        // console.log("audio_scope_data: loading data")

        this.chart.load({
          columns: [
            ["data"].concat(event.payload)
          ]
        })
      })


      this.chart = c3.generate({
        bindto: '#audioScope',
        oninit: () => {
          // removes the white background
          document.querySelector('#audioScope g.c3-chart > g.c3-event-rects').removeAttribute('style')
        },
        transition: { duration: null },
        data: {
          columns: [],
          type: 'area',
          colors: {
            'data': '#00FF00'
          }

        },
        color: {
          // pattern: ['#0f0']
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
            tick: { count: 1 },
            padding: 0
          },
          y: {
            padding: 0,
            show: true,
            min: 0,
            max: 50,
            tick: { count: 1 }

          }
        }
      }) 
    } // mounted()

  },
  MultiCH: {
    mounted() {
      this.el.addEventListener("wheel", event => {
        var isScrollUp = (event.deltaY < 0)

        this.pushEvent("multi_ch", {is_up: isScrollUp})
      })
    }
  }
}
export default ControlHooks
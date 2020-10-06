let ControlHooks = {
  AudioScope: {
    mounted() {
      console.log("Hook: AudioScope: mounted()")

      this.handleEvent("audio_scope_data", (event) => {
        console.log("audio_scope_data: loading data")

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
          document.querySelector('g.c3-chart > g.c3-event-rects').removeAttribute('style')
        },
        data: {
          columns: [],
          type: 'area-spline'
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
import linearInterpolate from "./linear_interpolate"
import ColorMap from "./colormap"

let ControlHooks = {
  MultiCH: {
    mounted() {
      this.el.addEventListener("wheel", event => {
        event.preventDefault();

        var isScrollUp = (event.deltaY < 0)
        this.pushEvent("multi_ch", {is_up: isScrollUp})
      })
    }
  },
  BandScope: {
    mounted() {
      this.el.addEventListener("wheel", event => {
        event.preventDefault();
        var isScrollUp = (event.deltaY < 0)
        this.pushEvent("multi_ch", {is_up: isScrollUp})
      });

      this.el.addEventListener("mousemove", event => {
        console.log("mousemove", event)
      })

      this.el.addEventListener("mouseup", event => {
        // this doesn't work
        event.preventDefault();

        let svg = document.querySelector('svg#bandScope');
        let pt = svg.createSVGPoint();

        pt.x = event.clientX;
        pt.y = event.clientY;

        var cursorPt = pt.matrixTransform(svg.getScreenCTM().inverse());

        this.pushEvent("scope_clicked", {x: cursorPt.x, y: cursorPt.y})
      })
    }
  },
  AudioScopeCanvas: {
    updated() {
      this.theme = this.el.dataset.theme;
    },

    mounted() {
      console.log("audioscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")

      this.maxVal = 50
      this.multiplier = 1.25
      this.theme = this.el.dataset.theme;
      this.draw = true

      this.handleEvent("scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data;

          this.ctx.drawImage(this.canvas, 0, 1)

          let imgData = this.ctx.createImageData(data.length, 1)
          let i = 0;

          for(i; i < data.length; i++) {
            let val = linearInterpolate(data[i], 0, this.maxVal, 255, 0) * this.multiplier

            const mappedColor = ColorMap.applyMap(val, this.theme)

            imgData.data[4*i + 0] = mappedColor[0]
            imgData.data[4*i + 1] = mappedColor[1]
            imgData.data[4*i + 2] = mappedColor[2]
            imgData.data[4*i + 3] = mappedColor[3]

          }
          this.ctx.putImageData(imgData, 0, 0)
        }
      });
    }
  },
  BandScopeCanvas: {
    updated() {
      this.theme = this.el.dataset.theme
    },

    mounted() {
      console.log("bandscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")
      this.maxVal = 140
      this.multiplier = 3
      this.theme = this.el.dataset.theme
      this.draw = true

      this.handleEvent("band_scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data

          this.ctx.drawImage(this.canvas, 0, 1)

          let imgData = this.ctx.createImageData(data.length, 1)

          let i = 0;
          for(i; i < data.length; i++) {
            let val = linearInterpolate(data[i], 0, this.maxVal, 255, 0) * this.multiplier

            const mappedColor = ColorMap.applyMap(val, this.theme)

            imgData.data[4*i + 0] = mappedColor[0]
            imgData.data[4*i + 1] = mappedColor[1]
            imgData.data[4*i + 2] = mappedColor[2]
            imgData.data[4*i + 3] = mappedColor[3]

          }

          this.ctx.putImageData(imgData, 0, 0)
        }
      });
    }
  },
}
export default ControlHooks

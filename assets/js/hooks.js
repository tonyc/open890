import Interpolate from "./interpolate"
import ColorMap from "./colormap"

let Hooks = {
  RefLevelControl: {
    mounted() {
      console.log("ref level mount")
      this.el.addEventListener("wheel", event => {
        event.preventDefault();
        console.log("ref level wheel", event)

        var isScrollUp = (event.deltaY < 0)
        this.pushEvent("adjust_ref_level", {is_up: isScrollUp})
      })
    }
  },

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
    tuneToClick(event) {
      event.preventDefault()

      let svg = document.querySelector('svg#bandScope');
      let pt = svg.createSVGPoint();

      pt.x = event.clientX;
      pt.y = event.clientY;

      var cursorPt = pt.matrixTransform(svg.getScreenCTM().inverse());
      this.pushEvent("scope_clicked", {x: cursorPt.x, y: cursorPt.y, width: 640})
    },
    mounted() {
      this.el.addEventListener("wheel", event => {
        if (event.shiftKey) {
          event.preventDefault();
          var isScrollUp = (event.deltaY < 0)
          this.pushEvent("multi_ch", {is_up: isScrollUp})
        }
      });

      this.el.addEventListener("mousemove", event => {
        if (event.buttons && event.buttons == 1) {
          this.tuneToClick(event)
        }
      })

      this.el.addEventListener("mousedown", (event) => {
        this.tuneToClick(event)
      })
    }
  },
  AudioScope: {
    mounted() {
      this.el.addEventListener("mouseup", (event) => {
        event.preventDefault();
        this.pushEvent("cw_tune", {})
      })
    }
  },
  AudioScopeCanvas: {
    updated() {
      this.theme = this.el.dataset.theme;
    },

    clearScope() {
      if (this.ctx) {
        this.ctx.save();
        this.ctx.fillStyle = 'black';
        this.ctx.fillRect(0, 0, this.width, this.height)
        this.ctx.restore()
      }
    },

    mounted() {
      console.log("audioscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")

      this.multiplier = 0.6
      this.theme = this.el.dataset.theme;
      this.draw = true

      // these items should be computed or passed in via data- attributes
      this.maxVal = 50
      this.width = 212
      this.height = 50

      this.clearScope()

      this.el.addEventListener("click", (event) => {
        event.preventDefault();
        this.pushEvent("cw_tune", {})
      })

      this.handleEvent("scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data;

          this.ctx.drawImage(this.canvas, 0, 1)

          let imgData = this.ctx.createImageData(data.length, 1)
          let i = 0;

          for(i; i < data.length; i++) {
            let val = Interpolate.linear(data[i], 0, this.maxVal, 255, 0) * this.multiplier

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

    tuneToClick(event) {
      let rect = this.canvas.getBoundingClientRect()

      let scaleX = this.canvas.width / rect.width;
      let scaleY = this.canvas.height / rect.height;

      let x = (event.clientX - rect.left) * scaleX;
      let y = (event.clientY - rect.top) * scaleY;

      this.pushEvent("scope_clicked", {x: x, y: y, width: 1280})
    },

    clearScope() {
      if (this.ctx) {
        this.ctx.save();
        this.ctx.fillStyle = 'black';
        this.ctx.fillRect(0, 0, this.width, this.height)
        this.ctx.restore()
      }
    },

    mounted() {
      console.log("bandscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")
      // window.bandscope = this.ctx;

      // these items should be computed or passed in via data- attributes
      this.maxVal = 140
      this.width = 1280
      this.height = 200

      this.ctx.imageSmoothingEnabled = false;
      this.ctx.imageSmoothingQuality = 'high';
      // this.ctx.globalCompositeOperation = 'color'
      console.log("smoothing", this.ctx.imageSmoothingEnabled);

      this.multiplier = 1.3
      this.theme = this.el.dataset.theme
      this.draw = true

      this.clearScope()

      this.handleEvent("clear_band_scope", (event) => {
        this.clearScope()
      })

      this.el.addEventListener("wheel", event => {
        if (event.shiftKey) {
          event.preventDefault();
          var isScrollUp = (event.deltaY < 0)
          this.pushEvent("multi_ch", {is_up: isScrollUp})
        }
      });

      this.el.addEventListener("mousemove", event => {
        if (event.buttons && event.buttons == 1) {
          this.tuneToClick(event)
        }
      })

      this.el.addEventListener("mousedown", event => {
        this.tuneToClick(event);
      })

      this.handleEvent("band_scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data

          this.ctx.drawImage(this.canvas, 0, 1)

          let imgData = this.ctx.createImageData(data.length * 2, 1)

          let i = 0;

          for(i; i < data.length; i++) {

            // interpolate signal strength to 0..255
            let val = Interpolate.linear(data[i], 0, 140, 255, 0) * this.multiplier

            const mappedColor = ColorMap.applyMap(val, this.theme)

            imgData.data[8*i + 0] = mappedColor[0]
            imgData.data[8*i + 1] = mappedColor[1]
            imgData.data[8*i + 2] = mappedColor[2]
            imgData.data[8*i + 3] = mappedColor[3]

            imgData.data[8*i + 4] = mappedColor[0]
            imgData.data[8*i + 5] = mappedColor[1]
            imgData.data[8*i + 6] = mappedColor[2]
            imgData.data[8*i + 7] = mappedColor[3]


            // imgData.data[4*(i*2) + 0 + ] = mappedColor[0]
            // imgData.data[4*(i*2) + 1 + ] = mappedColor[1]
            // imgData.data[4*(i*2) + 2 + ] = mappedColor[2]
            // imgData.data[4*(i*2) + 3 + ] = mappedColor[3]

          }

          this.ctx.putImageData(imgData, 0, 0)
        }
      });
    }
  },
}
export default Hooks

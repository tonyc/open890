import Interpolate from "./interpolate"
import ColorMap from "./colormap"

let Hooks = {
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

      //this.el.addEventListener("mousemove", event => {
      //  console.log("mousemove", event)
      //})

      this.el.addEventListener("mouseup", event => {
        // this doesn't work
        event.preventDefault();

        let svg = document.querySelector('svg#bandScope');
        let pt = svg.createSVGPoint();

        pt.x = event.clientX;
        pt.y = event.clientY;


        var cursorPt = pt.matrixTransform(svg.getScreenCTM().inverse());
        console.log("scope clicked", cursorPt)

        this.pushEvent("scope_clicked", {x: cursorPt.x, y: cursorPt.y})
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

      // these items should be computed or passed in via data- attributes
      this.maxVal = 140
      this.width = 640
      this.height = 200

      this.multiplier = 1.25
      this.theme = this.el.dataset.theme
      this.draw = true

      this.clearScope()

      this.handleEvent("clear_band_scope", (event) => {
        this.clearScope()
      })

      this.el.addEventListener("mouseup", event => {
        event.preventDefault();
        //console.log("bandscope clicked", event)

        let rect = this.canvas.getBoundingClientRect()

        let scaleX = this.canvas.width / rect.width;
        let scaleY = this.canvas.height / rect.height;

        let x = (event.clientX - rect.left) * scaleX;
        let y = (event.clientY - rect.top) * scaleY;


        //console.log("computed:", {x, y})

        this.pushEvent("scope_clicked", {x, y})
      })

      this.handleEvent("band_scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data

          this.ctx.drawImage(this.canvas, 0, 1)

          let imgData = this.ctx.createImageData(data.length, 1)

          let i = 0;
          for(i; i < data.length; i++) {

            // interpolate signal strength to 0..255
            let val = Interpolate.linear(data[i], 0, 140, 255, 0) * this.multiplier

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
export default Hooks

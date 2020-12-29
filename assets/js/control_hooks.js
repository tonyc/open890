import linearInterpolate from "./linear_interpolate"

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
    mounted() {
      console.log("audioscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")
      this.draw = true;

      this.handleEvent("scope_data", (event) => {
        if (this.draw) {
          let data = event.scope_data;

          this.ctx.drawImage(this.canvas, 0, 1)

          for(var i = 0; i < data.length; i++) {
            let imgData = this.ctx.createImageData(1, 1)

            let val = linearInterpolate(data[i], 0, 50, 255, 0)

            let pixel = imgData.data;
            pixel[0] = pixel[1] = pixel[2] = val
            pixel[3] = 255

            this.ctx.putImageData(imgData, i, 0)
          }
        }

      });
    }
  },
  BandScopeCanvas: {
    mounted() {
      console.log("bandscope canvas mounted")

      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")
      this.maxVal = 140
      this.multiplier = 2.5

      this.handleEvent("band_scope_data", (event) => {
        let data = event.scope_data

        this.ctx.drawImage(this.canvas, 0, 1)

        for(var i = 0; i < data.length; i++) {
          let imgData = this.ctx.createImageData(1, 1)

          let val = linearInterpolate(data[i], 0, this.maxVal, 255, 0) * this.multiplier

          let pixel = imgData.data
          pixel[0] = val
          pixel[1] = val
          pixel[2] = val
          pixel[3] = 255

          this.ctx.putImageData(imgData, i, 0)
        }
      });
    }
  },
}
export default ControlHooks

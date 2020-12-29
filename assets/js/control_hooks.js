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

      this.el.addEventListener("click", event => {
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
      //this.canvas = document.getElementById("AudioScopeCanvas")
      //this.ctx = canvas.getContext("2d")

      var self = this;

      this.handleEvent("scope_data", (event) => {
        let data = event.scope_data;

        let canvas = document.getElementById("AudioScopeCanvas")
        let ctx = canvas.getContext("2d")

        for(var i = 0; i < data.length; i++) {
          let imgData = ctx.createImageData(1, 1)
          let d = imgData.data;

          let c = Math.floor(Math.random() * 255)
          //console.log("color", c)
          //console.log(data)

          let value = data[i]

          let xMin = 255
          let xMax = 0

          let yMin = 0
          let yMax = 50

          let percent = (value - yMin) / (yMax - yMin)
          let val = percent * (xMax - xMin) + xMin


          d[0] = val
          d[1] = 0
          d[2] = 0
          d[3] = 255

          ctx.putImageData(imgData, i, 5)
        }

        //let canvas = document.getElementById("AudioScopeCanvas")
        //let ctx = canvas.getContext("2d")
        //let imgData = ctx.createImageData(213, 1)

        //for(var i = 0; i < 213; i++) {
        //  let randColor = Math.floor(Math.random() * 255)

        //  imgData[0] = randColor;
        //  imgData[1] = randColor;
        //  imgData[2] = randColor;
        //  imgData[3] = randColor;

        //  ctx.putImageData(imgData, 0, 0)
        //}


        //console.log("scope_data:", event)
      })
    },

    randomColor() {
      Math.floor(Math.random() * 255)
    }
  }
}
export default ControlHooks

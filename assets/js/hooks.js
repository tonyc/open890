import Interpolate from "./interpolate"
import ColorMap from "./colormap"
import socket from "./socket"

function PCMPlayer(t){this.init(t)}PCMPlayer.prototype.init=function(t){this.option=Object.assign({},{encoding:"16bitInt",channels:1,sampleRate:8e3,flushingTime:1e3},t),this.samples=new Float32Array,this.flush=this.flush.bind(this),this.interval=setInterval(this.flush,this.option.flushingTime),this.maxValue=this.getMaxValue(),this.typedArray=this.getTypedArray(),this.createContext()},PCMPlayer.prototype.getMaxValue=function(){var t={"8bitInt":128,"16bitInt":32768,"32bitInt":2147483648,"32bitFloat":1};return t[this.option.encoding]?t[this.option.encoding]:t["16bitInt"]},PCMPlayer.prototype.getTypedArray=function(){var t={"8bitInt":Int8Array,"16bitInt":Int16Array,"32bitInt":Int32Array,"32bitFloat":Float32Array};return t[this.option.encoding]?t[this.option.encoding]:t["16bitInt"]},PCMPlayer.prototype.createContext=function(){this.audioCtx=new(window.AudioContext||window.webkitAudioContext),this.gainNode=this.audioCtx.createGain(),this.gainNode.gain.value=1,this.gainNode.connect(this.audioCtx.destination),this.startTime=this.audioCtx.currentTime},PCMPlayer.prototype.isTypedArray=function(t){return t.byteLength&&t.buffer&&t.buffer.constructor==ArrayBuffer},PCMPlayer.prototype.feed=function(t){if(this.isTypedArray(t)){t=this.getFormatedValue(t);var e=new Float32Array(this.samples.length+t.length);e.set(this.samples,0),e.set(t,this.samples.length),this.samples=e}},PCMPlayer.prototype.getFormatedValue=function(t){t=new this.typedArray(t.buffer);var e,i=new Float32Array(t.length);for(e=0;e<t.length;e++)i[e]=t[e]/this.maxValue;return i},PCMPlayer.prototype.volume=function(t){this.gainNode.gain.value=t},PCMPlayer.prototype.destroy=function(){this.interval&&clearInterval(this.interval),this.samples=null,this.audioCtx.close(),this.audioCtx=null},PCMPlayer.prototype.flush=function(){if(this.samples.length){var t,e,i,n,a,s=this.audioCtx.createBufferSource(),r=this.samples.length/this.option.channels,o=this.audioCtx.createBuffer(this.option.channels,r,this.option.sampleRate);for(e=0;e<this.option.channels;e++)for(t=o.getChannelData(e),i=e,a=50,n=0;n<r;n++)t[n]=this.samples[i],n<50&&(t[n]=t[n]*n/50),r-51<=n&&(t[n]=t[n]*a--/50),i+=this.option.channels;this.startTime<this.audioCtx.currentTime&&(this.startTime=this.audioCtx.currentTime),console.log("start vs current "+this.startTime+" vs "+this.audioCtx.currentTime+" duration: "+o.duration),s.buffer=o,s.connect(this.gainNode),s.start(this.startTime),this.startTime+=o.duration,this.samples=new Float32Array}};

let Hooks = {
  ScopeWheelEvent: {
    wheel(me, event) {

      event.preventDefault();
      if (me.locked) { return; }

      var isScrollUp = (event.deltaY < 0);
      var stepSize = 5;

      if (event.shiftKey) {
        stepSize = 0
      } else if(event.altKey) {
        stepSize = 3
      }

      if (isScrollUp) {
        if (event.shiftKey) {
          this.pushEvent("step_tune_up", {stepSize: stepSize})
        } else {
          this.pushEvent("multi_ch", {is_up: true})

        }
      } else {
        if (event.shiftKey) {
          this.pushEvent("step_tune_down", {stepSize: stepSize})
        } else {
          this.pushEvent("multi_ch", {is_up: false})
        }
      }

    }
  },
  AudioStream: {
    mounted() {
      console.log("AudioStream: mounted")

      this.player = new PCMPlayer({
        encoding: '16bitInt',
        channels: 1,
        sampleRate: 16000,
        flushingTime: 125
      })

      this.audioStreamChannel = socket.channel("radio:audio_stream", {})
      this.audioStreamChannel.join()
        .receive("ok", (resp) => { console.log("joined audio stream channel, resp:", resp) })
        .receive("error", (resp) => {
           console.log("unable to join audio stream channel:", resp)
        })

      this.audioStreamChannel.on("audio_data", (data) => {
        if (this.player) {
          let buff = new Uint8Array(data.payload);
          this.player.feed(buff)
        }
      })
    }
  },
  Tabs: {
    mounted() {
      $('#ButtonTabs .item').tab();
    }

  },
  PopoutBandscope: {
    mounted() {
      console.log("popoutbandscope mounted")
      let me = this;
      this.el.addEventListener("click", event => {
        event.preventDefault()

        let id = this.el.dataset.connectionId
        let url = `/connections/${id}/bandscope?popout`
        me.window = window.open(url, `bandscope-${id}`, "width=1500,height=780,popup=true,menubar=off,scrollbars=off")
      })
    }
  },

  MaintainAttrs: {
    attrs(){ return this.el.getAttribute("data-attrs").split(", ") },
    beforeUpdate(){ this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)]) },
    updated(){ this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val)) }
  },

  BandModal: {
    mounted() {
      this.el.addEventListener("click", event => {
        console.log("bandmodal clicked")
        // if (this.el == event.target) {
        //   event.stopPropagation();
        // }
      })

      // window.document.querySelector("#BandModalClose").addEventLister("click", event => {
      //   event.preventDefault()
      //   console.log("BandModalClose click")
      // })
    }

  },
  ActiveVFO: {
    mounted() {
      console.log("ActiveVFO mounted")
      this.el.addEventListener("click", event => {
        this.pushEvent("toggle_band_selector")
      })

      // this.el.addEventListener("wheel", event => {
      //   event.preventDefault()
      // })
    }

  },

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

  RitXitControl: {
    copyTouch({identifier, pageX, pageY}) {
      return { identifier, pageX, pageY }
    },

    mounted() {
      this.el.addEventListener("wheel", (event) => {
        event.preventDefault();

        var isScrollUp = event.deltaY < 0;
        this.pushEvent("adjust_rit_xit", {is_up: isScrollUp})
      })

      this.el.addEventListener("touchstart", (event) => {
        var me = this;

        if (event.changedTouches[0]) {
          let touch = event.changedTouches[0];
          me.prevTouch = this.copyTouch(touch);
        }
      })

      this.el.addEventListener("touchend", (event) => {
        var me = this;
        event.preventDefault();
        me.prevTouch = null;
      })

      this.el.addEventListener("touchmove", (event) => {
        event.preventDefault();
        var me = this;

        if (event.changedTouches[0]) {
          if (me.prevTouch) {
            let touch = event.changedTouches[0];

            let deltaX = touch.pageX - me.prevTouch.pageX;
            let deltaY = touch.pageY - me.prevTouch.pageY;

            let isUp = deltaX > 0;
            console.log("move dx/dy:", deltaX, deltaY);

            if (Math.abs(deltaX) > 5) {
              this.pushEvent("adjust_rit_xit", {is_up: isUp})
            }
          }
        }
      })

      //this.el.addEventListener("mousedown", (event) => {
      //  event.preventDefault();
      //  me.dragStartCoord = event.x;

      //  console.log("RIT/XIT mouseDown", event.x)
      //})


      //this.el.addEventListener("mouseup", (event) => {
      //  event.preventDefault();


      //  console.log("RIT/XIT mouseUp", event.x)
      //})

      //this.el.addEventListener("mousemove", event => {
      //  event.preventDefault();

      //  if (event.buttons && event.buttons == 1) {
      //    console.log("rit/xit drag", event)
      //  }
      //})
    },


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
      let me = this;

      let scaleKey = 'bandscope.spectrum_scale'
      this.spectrumScale = localStorage.getItem(scaleKey) || 140
      this.locked = false;

      this.handleEvent("lock_state", (event) => {
        me.locked = event.locked;
      })

      this.el.addEventListener("wheel", event => {
        ScopeWheelEvent.wheel(me, event);
      });

      this.el.addEventListener("mousemove", event => {
        if (me.locked) { return; }

        if (event.buttons && event.buttons == 1) {
          this.tuneToClick(event)
        }
      })

      this.el.addEventListener("mousedown", (event) => {
        if (me.locked) { return; }
        this.tuneToClick(event)
      })
    }
  },
  AudioScope: {
    mounted() {
      this.el.addEventListener("wheel", (event) => {
        event.preventDefault();
        let isScrollUp = (event.deltaY < 0);

        let dir = isScrollUp ? "up" : "down";
        let isShifted = event.shiftKey;

        console.log("audioScope wheel, dir:", dir, "shifted", isShifted, "event:", event);
        this.pushEvent("adjust_filter", {dir: dir, shift: isShifted})
      });

      this.el.addEventListener("click", (event) => {
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
      this.drawInterval = this.el.dataset.drawInterval;
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

    resumeDrawing(ctx) {
      ctx.packetCount = 0;
      ctx.draw = true;
    },

    mounted() {
      let me = this;

      this.resumeDrawtimer = null;
      console.log("bandscope canvas mounted")
      this.canvas = this.el
      this.ctx = this.canvas.getContext("2d")
      this.drawInterval = this.el.dataset.drawInterval;
      this.locked = false;

      this.maxVal = this.el.dataset.maxValue;
      this.width = this.el.getAttribute('width')
      this.height = this.el.getAttribute('height')

      this.ctx.imageSmoothingEnabled = false;
      this.ctx.imageSmoothingQuality = 'high';
      // this.ctx.globalCompositeOperation = 'color'
      console.log("smoothing", this.ctx.imageSmoothingEnabled);

      this.multiplier = 1.3
      this.theme = this.el.dataset.theme
      this.draw = true
      this.packetCount = 0;

      this.clearScope()

      this.handleEvent("lock_state", (event) => {
        me.locked = event.locked;
      })

      this.handleEvent("clear_band_scope", (event) => {
        this.clearScope()
      })

      this.el.addEventListener("wheel", event => {
        ScopeWheelEvent.wheel(me, event);
      });

      this.el.addEventListener("mousemove", event => {
        if (me.locked) { return; }

        if (event.buttons && event.buttons == 1) {
          this.tuneToClick(event)
        }
      })

      this.el.addEventListener("mousedown", event => {
        if (me.locked) { return; }
        this.tuneToClick(event);
      })

      this.handleEvent("freq_delta", (event) => {
        //console.log("freq_delta", event)
        // interpolate delta event.bs.low ... event.bs.high to the scope size
        this.draw = false

        if (this.resumeDrawTimer) {
          clearTimeout(this.resumeDrawTimer)
        }

        this.resumeDrawTimer = setTimeout(this.resumeDrawing, 200, this);

        let rect = this.canvas.getBoundingClientRect()
        let scaleX = this.canvas.width / rect.width

        let bs_delta = event.bs.high - event.bs.low

        let widthScale = bs_delta / this.canvas.width

        let canvasDelta = event.delta / widthScale
        let width = Math.abs(canvasDelta)

        //console.log("canvasDelta:", canvasDelta)

        this.ctx.drawImage(this.canvas, -canvasDelta, 0)

        if (canvasDelta < 0) {
          // left side
          this.ctx.fillStyle = '#000'
          this.ctx.fillRect(0, 0, width, this.canvas.height)
        } else if (canvasDelta > 0) {
          // right side
          this.ctx.fillStyle = '#000'
          this.ctx.fillRect(this.canvas.width - width, 0, width, this.height)
        }
      }).bind(this)

      this.handleEvent("band_scope_data", (event) => {
        this.packetCount += 1;

        if (this.draw && (this.packetCount % this.drawInterval) == 0) {
          this.packetCount = 0;
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

  Slider: {
    mounted() {
      this.action = this.el.dataset.clickAction
      this.wheelAction = this.el.dataset.wheelAction;

      this.el.addEventListener('wheel', (event) => {
        event.preventDefault();

        if (this.el.dataset.enabled !== "true") {
          return
        }
        var isScrollUp = (event.deltaY < 0)
        this.pushEvent(this.wheelAction, {is_up: isScrollUp})
      })

      this.el.addEventListener('click', (event) => {
        event.stopPropagation()
        event.preventDefault()

        if (this.el.dataset.enabled !== "true") {
          return
        }

        let coords = this.getClickCoords(event)
        let x = Math.floor(coords.x)

        this.pushEvent(this.action, {value: x})
      })

      this.el.addEventListener("mousemove", event => {
        if (this.el.dataset.enabled !== "true") {
          return;
        }

        if (event.buttons && event.buttons == 1) {
          let coords = this.getClickCoords(event)
          let x = Math.floor(coords.x)
          this.pushEvent(this.action, {value: x})
        }
      })
    },

    getClickCoords(event) {
      let rect = event.target.getBoundingClientRect();
      let x = event.clientX - rect.left; //x position within the element.
      let y = event.clientY - rect.top;  //y position within the element.

      return {x: x, y: y}
    }

  },

  SpectrumScaleForm: {
    mounted() {
      const key = 'bandscope.spectrum_scale'
      let val = localStorage.getItem(key)

      if (!val) {
        localStorage.setItem(key, 1.0)
      } else {
        this.pushEvent('spectrum_scale_changed', {value: val})
      }

      this.el.addEventListener('change', (event) => {
        const val = event.target.value;
        console.log("scale changed", val)

        localStorage.setItem(key, val)
        this.pushEvent('spectrum_scale_changed', {value: val})
      })
    }
  },

  WaterfallSpeedForm: {
    mounted() {
      console.log("WF speed form mounted")

      const key = 'bandscope.waterfall_speed'
      let wfSpeed = localStorage.getItem(key)

      if (!wfSpeed) {
        localStorage.setItem(key, '1')
      } else {
        this.pushEvent('wf_speed_changed', {value: wfSpeed})
      }

      this.el.addEventListener('change', (event) => {
        const val = event.target.value;

        localStorage.setItem(key, val)
        this.pushEvent('wf_speed_changed', {value: val})
      })
    }
  },
}
export default Hooks

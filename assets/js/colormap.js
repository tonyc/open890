import Interpolate from "./interpolate"
import ColorUtils from "./color_utils"

let ColorMap = {

  applyMap(val, name) {
    switch(name) {
      case "red":
        return this.red(val)
      case "green":
      case "phosphor-green":
        return this.green(val)
      case "phosphor-red":
        return this.red(val)
      case "grey":
      case "gray":
        return this.grayscale(val)
      case "hsl":
        return this.hsl(val)
      case "kenwood":
      default:
        return this.hslBlack(val)
    }
  },

  grayscale(val) {
    return [val, val, val, 255]
  },

  green(val) {
    return [0, val, 0, 255]
  },

  red(val) {
    return [val, 0, 0, 255]
  },

  hsl(val) {
    let hue = Interpolate.linear(val, 0, 255, 240, 0)
    let arr = ColorUtils.hsl2rgb(hue / 359.9, 1.0, 0.5)
    return [arr[0], arr[1], arr[2], 255]
  },

  hslBlack(val) {
    if (val < 7) {
      return [0, 0, 0, 255]
    } else {
      return this.hsl(val);
    }

  },




}

export default ColorMap

let ColorMap = {
  applyMap(val, name) {
    switch(name) {
      case "red":
        return this.red(val)
      case "green":
      case "phosphor-green":
        return this.green(val)
      case "red":
      case "phosphor-red":
        return this.red(val)
      case "grey":
      case "gray":
      case "kenwood":
      default:
        return this.grayscale(val)
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
  }

}

export default ColorMap

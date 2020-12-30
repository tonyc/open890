export default {
  linear(value, yMin, yMax, xMin, xMax) {
    let percent = (value - yMin) / (yMax - yMin)
    let val = percent * (xMax - xMin) + xMin

    return val;
  }
}

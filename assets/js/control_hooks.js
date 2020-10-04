let ControlHooks = {
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
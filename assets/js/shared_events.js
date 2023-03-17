let SharedEvents = {
  ScopeWheel: {
    wheel(me, event) {
      console.log("SharedEvents.ScopeWheel.wheel")

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
          me.pushEvent("step_tune_up", {stepSize: stepSize})
        } else {
          me.pushEvent("multi_ch", {is_up: true})

        }
      } else {
        if (event.shiftKey) {
          me.pushEvent("step_tune_down", {stepSize: stepSize})
        } else {
          me.pushEvent("multi_ch", {is_up: false})
        }
      }
    }
  }
}

export default SharedEvents

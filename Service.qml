import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// Auto-applies scripts/theme-cursor.py (cursor theming engine derived from
// jobo.big-cheese) on Omarchy palette changes.
Item {
  id: root

  property var shell: null

  readonly property string helper: localPath(Qt.resolvedUrl("scripts/theme-cursor.py"))
  readonly property string swapFlag: localPath(Qt.resolvedUrl("swapped"))
  readonly property string accent: String(Commons.Color.accent)
  readonly property string bg: String(Commons.Color.background)
  property bool swapped: false
  // Normal: accent border, bg interior. Swapped: accent interior, bg border.
  readonly property string fill: swapped ? bg : accent
  readonly property string outline: swapped ? accent : bg

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") !== 0) return ""
    try {
      var path = decodeURIComponent(value.substring(7))
      return path.indexOf("/") === 0 ? path : ""
    } catch (error) {
      return ""
    }
  }

  function run() {
    if (helper === "" || apply.running) {
      debounce.restart()
      return
    }
    apply.command = [helper, "apply", fill, outline, "default", "24"]
    apply.running = true
  }

  function toggleSwap() {
    setSwapped(!swapped)
  }

  function setSwapped(value) {
    swapped = value === true
    if (swapFlag !== "") {
      saveSwap.command = ["sh", "-c", "printf %s \"$1\" > \"$2\"", "save", swapped ? "1" : "0", swapFlag]
      saveSwap.running = true
    }
    run()
  }

  onAccentChanged: debounce.restart()
  onBgChanged: debounce.restart()

  Component.onCompleted: {
    if (swapFlag !== "") {
      loadSwap.command = ["cat", swapFlag]
      loadSwap.running = true
    } else {
      run()
    }
  }

  // ponytail: baseline defaults to default/24 inside theme-cursor.py, no per-theme size tracking; add when non-default cursor sizes matter.
  Timer {
    id: debounce
    interval: 500
    repeat: false
    onTriggered: root.run()
  }

  Process {
    id: apply
    stderr: SplitParser {
      onRead: function(line) { console.warn("omacursor: " + line) }
    }
    onExited: function(code) {
      if (code !== 0) console.warn("omacursor: apply failed " + code)
    }
  }

  Process {
    id: loadSwap
    stdout: StdioCollector {
      onStreamFinished: {
        root.swapped = text.trim() === "1"
        root.run()
      }
    }
    onExited: function(code) {
      if (code !== 0) root.run()
    }
  }

  Process {
    id: saveSwap
    onExited: function(code) {
      if (code !== 0) console.warn("omacursor: swap save failed " + code)
    }
  }
}

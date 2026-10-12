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
  readonly property string settingsFile: localPath(Qt.resolvedUrl("settings.toml"))
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
    if (settingsFile !== "") {
      saveSwap.command = ["sh", "-c", "printf 'swapped = %s\\n' \"$1\" > \"$2\"", "save", swapped ? "true" : "false", settingsFile]
      saveSwap.running = true
    }
    run()
  }

  onAccentChanged: debounce.restart()
  onBgChanged: debounce.restart()

  Component.onCompleted: {
    if (settingsFile !== "") {
      loadSwap.command = ["python3", "-c", "import sys,tomllib; print(tomllib.load(open(sys.argv[1],'rb')).get('swapped') is True)", settingsFile]
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
        root.swapped = text.trim() === "True"
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

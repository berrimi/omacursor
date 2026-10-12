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
  // State lives outside the plugin dir: writes under ~/.config/omarchy/plugins/
  // trip the shell's file watcher and reload the whole plugin on every click.
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omacursor"
  readonly property string settingsFile: stateDir + "/settings.toml"
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
    saveSwap.command = ["sh", "-c", "mkdir -p \"$1\" && printf 'swapped = %s\\n' \"$2\" > \"$1/settings.toml\"", "save", stateDir, swapped ? "true" : "false"]
    saveSwap.running = true
    run()
  }

  onAccentChanged: debounce.restart()
  onBgChanged: debounce.restart()

  Component.onCompleted: {
    loadSwap.command = ["python3", "-c", "import sys,tomllib; print(tomllib.load(open(sys.argv[1],'rb')).get('swapped') is True)", settingsFile]
    loadSwap.running = true
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

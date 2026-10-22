import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Effects
import qs.Commons
import qs.Ui

// Icon for io.github.berrimi.omacursor: left-click swaps accent fill <-> bg fill.
BarWidget {
  id: root
  moduleName: "io.github.berrimi.omacursor"

  readonly property var svc: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property bool swapped: svc ? svc.swapped === true : false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Re-apply when (re-)placed on the bar; the service outlives disable.
  Component.onCompleted: if (root.svc) root.svc.run()

  // The platform drops only the bar entry on disable, so the widget's own
  // destruction is the precise disable signal. Detached like the service's.
  Component.onDestruction: {
    if (root.svc && root.svc.cleanupScript !== "") {
      widgetCleanup.command = ["sh", "-c", "setsid sh \"$1\" >/dev/null 2>&1 < /dev/null &", "cleanup", root.svc.cleanupScript]
      widgetCleanup.running = true
    }
  }

  Process {
    id: widgetCleanup
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: cursorIcon
    tooltipText: root.swapped
      ? "omacursor · accent outline · click to switch to accent fill"
      : "omacursor · accent fill · click to switch to outline"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton && root.svc) root.svc.toggleSwap()
    }
  }

  Component {
    id: cursorIcon

    Item {
      Image {
        id: glyph
        anchors.fill: parent
        source: root.swapped
          ? Qt.resolvedUrl("assets/cursor-outline.svg")
          : Qt.resolvedUrl("assets/cursor-filled.svg")
        sourceSize.width: 64
        sourceSize.height: 64
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
        layer.enabled: true
      }

      MultiEffect {
        anchors.fill: glyph
        source: glyph
        colorization: 1.0
        colorizationColor: button.foreground
      }
    }
  }
}

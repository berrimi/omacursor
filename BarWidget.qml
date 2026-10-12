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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: cursorIcon
    tooltipText: root.swapped
      ? "omacursor · accent fill · click for accent outline"
      : "omacursor · accent outline · click for accent fill"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton && root.svc) root.svc.toggleSwap()
    }
  }

  Component {
    id: cursorIcon

    Item {
      anchors.fill: parent

      Image {
        id: glyph
        anchors.fill: parent
        source: root.swapped
          ? Qt.resolvedUrl("assets/cursor-filled.svg")
          : Qt.resolvedUrl("assets/cursor-outline.svg")
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

import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Shapes
import qs.Commons
import qs.Ui

// Icon for io.github.berrimi.omacursor: left-click swaps accent fill <-> bg fill.
BarWidget {
  id: root
  moduleName: "io.github.berrimi.omacursor"

  readonly property var svc: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property bool swapped: svc ? svc.swapped === true : false

  // The cursor glyphs as vector paths in a 32 unit box. Inline so the bar can
  // measure their tight bounds and fit them to Style.bar.iconSize; an Image
  // reports its padded viewBox, which renders the artwork undersized.
  readonly property string filledPath:
    "M26.4400 21.1000 C24.9300 19.3700 23.3100 17.6600 21.6000 16.0100 C22.7500 15.3000 23.9500 14.48" +
    "00 25.1600 13.4000 C25.6900 12.9200 25.9400 12.2200 25.8300 11.5300 C25.7200 10.8700 25.2900 10." +
    "3100 24.6700 10.0400 C18.4200 7.3100 12.7100 5.6500 7.2300 4.9800 C6.6000 4.9000 5.9900 5.1200 5" +
    ".5500 5.5800 C5.1100 6.0400 4.9200 6.6800 5.0300 7.2900 C5.9700 12.7300 7.5900 18.3600 10.0000 2" +
    "4.4900 C10.2500 25.1200 10.7600 25.5600 11.4200 25.6900 C12.1200 25.8300 12.8400 25.6000 13.3600" +
    " 25.0800 C14.4700 23.9500 15.2000 22.7200 15.8900 21.5300 C17.5700 23.2700 19.3100 24.9200 21.08" +
    "00 26.4700 C21.5000 26.8400 22.0500 27.0300 22.6000 27.0300 C22.9800 27.0300 23.3600 26.9400 23." +
    "7100 26.7500 C25.0200 26.0500 26.0500 25.0300 26.7500 23.7100 C27.2000 22.8600 27.0900 21.8000 2" +
    "6.4700 21.0900 Z"

  readonly property string outlinePath:
    "M6.5625 5.0250 C5.7375 5.2000 5.1063 5.9187 5.0188 6.7687 C4.9438 7.5375 5.9875 12.2500 7.0375 1" +
    "5.8750 C7.8313 18.6062 9.7500 24.0875 10.1562 24.7937 C10.6562 25.6375 11.7688 25.9563 12.7000 2" +
    "5.5188 C13.4000 25.1875 14.4375 23.9750 15.4062 22.3438 C15.5688 22.0688 15.7438 21.7750 15.7938" +
    " 21.7000 C15.8875 21.5500 15.8938 21.5625 17.1750 22.8250 C19.5188 25.1313 21.1313 26.5750 21.62" +
    "50 26.8062 C21.9250 26.9500 22.0500 26.9688 22.5938 26.9688 C23.1813 26.9688 23.2438 26.9563 23." +
    "6875 26.7437 C24.9188 26.1500 26.2063 24.8438 26.8000 23.5875 C26.9500 23.2625 26.9688 23.1437 2" +
    "6.9688 22.5938 C26.9688 22.0812 26.9438 21.9125 26.8313 21.6687 C26.6562 21.2937 24.9438 19.3875" +
    " 23.0438 17.4562 L21.6188 16.0125 L22.5125 15.4187 C23.5938 14.7063 24.8500 13.7125 25.2938 13.2" +
    "312 C25.8563 12.6125 26.0000 11.7687 25.6750 11.0500 C25.3500 10.3438 25.0312 10.1500 22.4125 9." +
    "0938 C17.4938 7.1125 12.7125 5.7625 8.4688 5.1562 C6.9250 4.9375 6.9500 4.9437 6.5625 5.0250 Z M" +
    "8.8750 7.7500 C11.6938 8.2250 14.4500 8.9187 17.3438 9.8875 C19.4313 10.5875 22.8438 11.9187 22." +
    "8375 12.0312 C22.8375 12.1250 22.0063 12.7500 20.9375 13.4625 C19.8813 14.1625 19.5750 14.4563 1" +
    "9.3188 14.9937 C19.1750 15.3000 19.1562 15.4187 19.1562 16.0000 C19.1562 17.0125 19.2500 17.1750" +
    " 20.7250 18.6562 C21.8625 19.7937 23.1125 21.1187 24.0250 22.1437 C24.4313 22.6000 24.4500 22.63" +
    "75 24.3813 22.7937 C24.1750 23.2500 23.4375 23.9937 22.7938 24.3938 L22.6188 24.5063 L21.7000 23" +
    ".6750 C21.1938 23.2188 20.0063 22.0812 19.0625 21.1500 C16.9875 19.1062 16.9688 19.0938 15.9062 " +
    "19.0938 C15.2563 19.0938 15.1938 19.1062 14.8125 19.2937 C14.2563 19.5688 13.9750 19.8813 13.331" +
    "3 20.9375 C12.8063 21.8000 12.0750 22.8500 12.0312 22.8000 C11.9938 22.7625 11.3500 21.0125 10.8" +
    "750 19.6562 C9.6938 16.2875 8.6937 12.7500 8.0125 9.5000 C7.6000 7.5750 7.6000 7.5625 7.7000 7.5" +
    "625 C7.7438 7.5625 8.2750 7.6437 8.8750 7.7500 Z"

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

    Shape {
      // The bar fits the path's measured bounds to Style.bar.iconSize.
      width: 32
      height: 32
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: button.foreground
        strokeWidth: 0
        PathSvg { path: root.swapped ? root.outlinePath : root.filledPath }
      }
    }
  }
}

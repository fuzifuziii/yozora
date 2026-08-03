import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "fuzi.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "fuzi"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("fuzi-shell shell toggle fuzi.menu '{\"menu\":\"root\"}'")
    }
  }
}

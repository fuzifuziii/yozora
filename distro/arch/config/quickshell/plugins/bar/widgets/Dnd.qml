import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fuzi.dnd"

  readonly property var notificationService: bar?.shell?.firstPartyServiceFor("fuzi.notifications")
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰂛"
    active: root.dnd
    tooltipText: root.dnd ? "Allow notifications" : "Silence notifications"
    onPressed: if (root.notificationService) root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)
  }
}

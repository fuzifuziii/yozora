import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "../../notifications/components"

BarWidget {
  id: root
  moduleName: "fuzi.dnd"

  readonly property var notificationService: bar?.shell?.firstPartyServiceFor("fuzi.notifications")
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false
  property bool historyOpen: false
  property bool showPending: true
  readonly property bool opened: historyOpen

  function open() { historyOpen = true }
  function close() { historyOpen = false }
  function toggle() { historyOpen = !historyOpen }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰂛"
    active: root.dnd
    tooltipText: "Notification history"
    onPressed: if (root.bar) root.toggle()
  }

  PopupCard {
    id: historyPopup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.historyOpen
    contentWidth: Math.min(Style.space(390), availableCardWidth)
    contentHeight: Math.min(Style.space(560), availableCardHeight)
    padding: Style.spacing.panelPadding

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.spacing.rowGap

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.rowPaddingX

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(2)
          Text {
            text: "Notifications"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
          Text {
            text: root.showPending ? "Unread" : "Recently seen"
            color: Qt.darker(Color.foreground, 1.4)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Button {
          Layout.fillWidth: true
          text: "Unread" + (root.notificationService ? " (" + root.notificationService.pendingModel.count + ")" : "")
          selected: root.showPending
          onClicked: root.showPending = true
        }
        Button {
          Layout.fillWidth: true
          text: "History" + (root.notificationService ? " (" + root.notificationService.pastModel.count + ")" : "")
          selected: !root.showPending
          onClicked: root.showPending = false
        }
      }

      Toggle {
        Layout.fillWidth: true
        label: "Do not disturb"
        description: root.dnd ? "Notifications are silenced" : "Notifications are allowed"
        checked: root.dnd
        foreground: Color.foreground
        accent: Color.accent
        onClicked: if (root.notificationService) root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Util.alpha(Color.foreground, 0.12)
      }

      ScrollView {
        id: notificationScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
          width: notificationScroll.availableWidth
          spacing: Style.space(8)

          Repeater {
            model: root.notificationService
              ? (root.showPending ? root.notificationService.pendingModel : root.notificationService.pastModel)
              : null

            delegate: Item {
              id: historySlot
              required property int index
              required property string app
              required property string appIcon
              required property string summary
              required property string body
              required property string image
              required property string glyph
              required property int urgency
              required property double timestamp

              width: notificationScroll.availableWidth
              implicitHeight: card.implicitHeight

              NotificationCard {
                id: card
                anchors.fill: parent
                app: historySlot.app
                appIcon: historySlot.appIcon
                summary: historySlot.summary
                body: historySlot.body
                image: historySlot.image
                glyph: historySlot.glyph
                urgency: historySlot.urgency
                timestamp: historySlot.timestamp
                cornerRadius: Style.cornerRadius
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onCloseRequested: {
                  if (root.notificationService) {
                    if (root.showPending) root.notificationService.dismissPending(historySlot.index)
                    else root.notificationService.dismissPast(historySlot.index)
                  }
                }
              }
            }
          }

          Text {
            visible: !root.notificationService || (root.showPending
              ? root.notificationService.pendingModel.count === 0
              : root.notificationService.pastModel.count === 0)
            width: parent.width
            text: root.showPending ? "No unread notifications" : "No notification history"
            color: Qt.darker(Color.foreground, 1.4)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            topPadding: Style.space(24)
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Button {
          Layout.fillWidth: true
          iconText: "󰄬"
          text: "Mark all read"
          bordered: true
          enabled: !!root.notificationService && root.notificationService.pendingModel.count > 0
          onClicked: root.notificationService.markAllSeen()
        }
        Button {
          Layout.fillWidth: true
          iconText: "󰆴"
          text: "Clear history"
          bordered: true
          enabled: !!root.notificationService && root.notificationService.pastModel.count > 0
          onClicked: root.notificationService.clearPast()
        }
      }
    }
  }
}

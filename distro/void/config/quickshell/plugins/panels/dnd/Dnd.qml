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
  property int phraseIndex: 0
  readonly property bool opened: historyOpen
  readonly property var quietPhrases: ["CATCHING A BREATH", "KEEPING WATCH", "NOTHING KNOCKING", "QUIET FOR NOW"]

  function open() { historyOpen = true }
  function close() { historyOpen = false }
  function toggle() { historyOpen = !historyOpen }

  Timer {
    interval: 5000
    running: root.historyOpen && !root.dnd && root.notificationService
      && root.notificationService.pendingModel.count === 0
    repeat: true
    onTriggered: root.phraseIndex++
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.dnd ? "󰂛" : "󰂚"
    active: false
    tooltipText: "Notification history"
    onPressed: function(button) {
      if (button === Qt.RightButton) {
        if (root.notificationService) root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)
      } else if (root.bar) {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: historyPopup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.historyOpen
    contentWidth: Style.space(380)
    contentHeight: Style.space(560)
    padding: Style.spacing.popupPadding

    ColumnLayout {
      id: historyColumn
      anchors.fill: parent
      spacing: Style.space(14)

      Item {
        Layout.fillWidth: true
        implicitHeight: Math.max(notificationIcon.implicitHeight, notificationLabels.implicitHeight, dndSwitch.implicitHeight)

        Text {
          id: notificationIcon
          text: "󰂚"
          color: Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.display
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        ToggleSwitch {
          id: dndSwitch
          checked: !root.dnd
          foreground: root.bar ? root.bar.foreground : Color.foreground
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          onToggled: if (root.notificationService) root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)

          PanelToolTip {
            visible: dndSwitch.containsMouse
            text: root.dnd ? "Allow notifications" : "Silence notifications"
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }
        }

        Column {
          id: notificationLabels
          anchors.left: notificationIcon.right
          anchors.leftMargin: Style.space(14)
          anchors.right: dndSwitch.left
          anchors.rightMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            text: "Notifications"
            width: parent.width
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            text: {
              if (root.dnd) return "KEEPING IT QUIET"
              var unread = root.notificationService ? root.notificationService.pendingModel.count : 0
              if (unread > 0) return unread + (unread === 1 ? " ping waiting" : " pings waiting")
              return root.quietPhrases[root.phraseIndex % root.quietPhrases.length]
            }
            width: parent.width
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
            elide: Text.ElideRight
          }
        }
      }

      PanelSeparator {
        Layout.fillWidth: true
        foreground: root.bar ? root.bar.foreground : Color.foreground
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Button {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.spacing.controlHeight + Style.space(8)
          text: "Fullscreen"
          tooltipText: "Hide notification popups on fullscreen screens"
          selected: root.notificationService ? root.notificationService.doNotDisturbFullscreen : false
          bordered: true
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.notificationService) root.notificationService.setDoNotDisturbFullscreen(!root.notificationService.doNotDisturbFullscreen)
        }
        Button {
          Layout.preferredHeight: Style.spacing.controlHeight + Style.space(8)
          iconText: "󰂚"
          text: "Unread " + (root.notificationService ? root.notificationService.pendingModel.count : 0)
          selected: root.showPending
          bordered: true
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.showPending = true
        }
        Button {
          Layout.preferredHeight: Style.spacing.controlHeight + Style.space(8)
          iconText: "󰋚"
          text: "History " + (root.notificationService ? root.notificationService.pastModel.count : 0)
          selected: !root.showPending
          bordered: true
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.showPending = false
        }
      }

      PanelSeparator {
        Layout.fillWidth: true
        foreground: root.bar ? root.bar.foreground : Color.foreground
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
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.notificationService) root.notificationService.markAllSeen()
        }
        Button {
          Layout.fillWidth: true
          iconText: "󰆴"
          text: "Clear history"
          bordered: true
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.notificationService) root.notificationService.clearPast()
        }
      }
    }
  }
}

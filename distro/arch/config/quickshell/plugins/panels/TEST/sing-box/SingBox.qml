import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fuzi.sing-box"

  property bool opened: false
  property bool online: false
  property string subscriptionUrl: ""
  property string actionStatus: ""
  readonly property string adminScript: Quickshell.env("FUZI_PATH") + "/bin/fuzi-singbox-admin"

  readonly property string statusText: online ? "Sing-box · VPN on" : "Sing-box · VPN off"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() { close() }

  function refresh() {
    statusProc.running = false
    statusProc.running = true
  }

  function runAction(action) {
    actionStatus = action === "start" ? "Starting..." : (action === "stop" ? "Stopping..." : "Restarting...")
    actionProc.command = ["pkexec", adminScript, action]
    actionProc.running = true
  }

  function applyUrl(url) {
    if (!url) return
    actionStatus = "Applying config..."
    actionProc.command = ["pkexec", adminScript, "url", url]
    actionProc.running = true
  }

  Component.onCompleted: refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    text: "󰖂"
    active: root.online
    tooltipText: root.statusText
    onPressed: function(mouseButton) { root.toggle() }
    onWheelMoved: function(delta) { root.refresh() }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: subscriptionField
    contentWidth: popup.fittedContentWidth(Style.space(330))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)
    onOpenChanged: if (open) Qt.callLater(function() { subscriptionField.forceActiveFocus() })

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Column {
          width: parent.width - refreshButton.implicitWidth - Style.space(10)
          spacing: 0

          Text {
            text: root.online ? "Sing-box" : "Sing-box offline"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.actionStatus !== "" ? root.actionStatus : "Use a subscription URL"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        Button {
          id: refreshButton
          iconText: "󰑐"
          foreground: root.bar.foreground
          tooltipText: "Refresh"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root.refresh()
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        TextField {
          id: subscriptionField
          width: parent.width - applyUrlButton.implicitWidth - Style.space(6)
          text: root.subscriptionUrl
          placeholderText: "Subscription URL"
          foreground: root.bar.foreground
          focus: popup.open
          onTextChanged: root.subscriptionUrl = text
        }

        Button {
          id: applyUrlButton
          text: "Apply"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          fontFamily: root.bar.fontFamily
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          onClicked: root.applyUrl(subscriptionField.text)
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          text: "Start"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          fontFamily: root.bar.fontFamily
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          enabled: !root.online
          onClicked: root.runAction("start")
        }

        Button {
          text: "Stop"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          fontFamily: root.bar.fontFamily
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          enabled: root.online
          onClicked: root.runAction("stop")
        }

        Button {
          text: "Restart"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          fontFamily: root.bar.fontFamily
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          enabled: true
          onClicked: root.runAction("restart")
        }
      }
    }
  }

  Process {
    id: statusProc
    command: [adminScript, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.online = String(text || "").trim() === "active"
    }
    onExited: function(code) { if (code !== 0) root.online = false }
  }

  Process {
    id: actionProc
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") root.actionStatus = String(text).trim()
    }
    onExited: function(code) {
      if (code === 0) root.actionStatus = "Done"
      else if (!root.actionStatus) root.actionStatus = "Action failed"
      root.refresh()
    }
  }
}

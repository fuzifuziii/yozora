import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "fuzi.media"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("fuzi.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""

  property bool popupOpen: false
  property var cavaLevels: []
  property real recordAngle: 0

  function close() { popupOpen = false }
  function updateCava(line) {
    var values = String(line || "").trim().split(/[; ,]+/)
    var next = []
    for (var i = 0; i < values.length; i++) {
      var value = Number(values[i])
      if (!isNaN(value)) next.push(Math.max(0, Math.min(1, value / 100)))
    }
    if (next.length > 0) cavaLevels = next
  }
  function cavaLevel(index) {
    if (!root.activePlayer || !root.activePlayer.isPlaying) return 0.12
    return root.cavaLevels.length > index ? Math.min(1, root.cavaLevels[index] * 1.25) : 0.12
  }
  property real maxLabelWidth: 180
  readonly property real openPanelIndicatorWidth: button.glyphPaintedWidth

  visible: true
  implicitWidth: Style.bar.iconSlot
  implicitHeight: barSize

  BarIconButton {
    id: button
    anchors.left: root.vertical ? undefined : parent.left
    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    anchors.verticalCenter: parent.verticalCenter
    width: Style.bar.iconSlot
    height: root.barSize
    bar: root.bar
    text: "󰝚"
    tooltipText: ""

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton) {
        if (root.activePlayer && root.mediaService) root.mediaService.runAction("next", false)
      } else {
        root.popupOpen = !root.popupOpen
      }
    }

    onWheelMoved: function(delta) {
      if (!root.activePlayer || !root.mediaService) return
      root.mediaService.runAction(delta > 0 ? "previous" : "next", false)
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    centerOnBar: true
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        id: visualizer
        width: parent.width
        height: Style.space(100)
        spacing: Style.space(28)

        Item {
          id: record
          width: Style.space(82)
          height: width
          anchors.verticalCenter: parent.verticalCenter
          rotation: root.recordAngle
          transform: Translate { x: Style.space(4) }

          BorderSurface {
            anchors.fill: parent
            radius: Style.spacing.labelGap
            clip: true
            color: "#161616"
            borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

            Image {
              anchors.fill: parent
              anchors.margins: Style.space(5)
              source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              opacity: source !== "" ? 0.9 : 0
            }

            Repeater {
              model: 4
              Rectangle {
                required property int index
                width: parent.width - Style.space(16) - index * Style.space(12)
                height: 1
                radius: 1
                anchors.centerIn: parent
                rotation: index * 45
                color: Util.alpha(root.bar.foreground, 0.18)
              }
            }

            Rectangle {
              anchors.centerIn: parent
              width: Style.space(14)
              height: width
              radius: width / 2
              color: root.bar.foreground
              border.color: Color.accent
              border.width: Style.space(2)
            }
          }
        }

        Item {
          id: visualizerInfo
          width: parent.width - record.width - parent.spacing
          height: parent.height
          anchors.verticalCenter: parent.verticalCenter

          Row {
            id: spectrumRow
            width: parent.width
            height: Style.space(52)
            spacing: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
              model: 28

              Rectangle {
                required property int index
                width: Math.max(2, Style.space(3))
                height: Style.space(8) + root.cavaLevel(index) * Style.space(45)
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: index % 4 === 0 ? Color.accent : root.bar.foreground
                opacity: root.activePlayer && root.activePlayer.isPlaying ? 0.95 : 0.35

              }
            }
          }

        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰒮"
          width: Style.space(40)
          height: Style.space(36)
          foreground: root.bar.foreground
          bordered: true
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
          width: Style.space(40)
          height: Style.space(36)
          foreground: root.bar.foreground
          bordered: true
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          iconSize: Style.font.iconLarge
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: "󰒭"
          width: Style.space(40)
          height: Style.space(36)
          foreground: root.bar.foreground
          bordered: true
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        }
      }

      PanelSeparator {
        visible: root.sourcePlayers.length > 0
        foreground: root.bar.foreground
      }

      Column {
        id: sourceList
        visible: root.sourcePlayers.length > 0
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
            readonly property string sourceTitle: player ? (player.trackTitle || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? player.trackArtist : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
            borderSpec: selected ? Border.controlSpec("selected", root.bar.foreground, Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  text: sourceRow.sourceTitle
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.mediaService) root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 40
    repeat: true
    running: root.activePlayer && root.activePlayer.isPlaying
    onTriggered: root.recordAngle = (root.recordAngle + 2.4) % 360
  }

  Connections {
    target: root.activePlayer
    function onIsPlayingChanged() {
      if (!root.activePlayer || !root.activePlayer.isPlaying) root.cavaLevels = []
    }
  }

  Process {
    id: cavaProc
    command: ["cava", "-p", Quickshell.env("FUZI_PATH") + "/config/cava/fuzi-media.conf"]
    running: root.activePlayer && root.activePlayer.isPlaying
    stdout: SplitParser { onRead: function(line) { root.updateCava(line) } }
  }
}

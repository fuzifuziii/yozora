import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fuzi.system-monitor"

  property bool opened: false
  property real cpuUsage: 0
  property real memUsage: 0
  property real memUsedGb: 0
  property real memTotalGb: 0
  property real load1: 0
  property real load5: 0
  property real load15: 0
  property real lastCpuTotal: 0
  property real lastCpuIdle: 0
  property bool haveCpuBaseline: false
  property int historyLimit: 28
  property var cpuHistory: []
  property var memHistory: []
  property var processes: []
  property string statsScript: String(Qt.resolvedUrl("SystemMonitorStats.sh")).replace(/^file:\/\//, "")

  readonly property bool busy: cpuUsage >= 0.75 || memUsage >= 0.80
  readonly property string icon: busy ? "󰻠" : "󰍛"
  readonly property string tooltip: "CPU " + percent(cpuUsage) + "  RAM " + percent(memUsage)

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() { close() }

  function percent(value) {
    return Math.round(Math.max(0, Math.min(1, value)) * 100) + "%"
  }

  function pushHistory(name, value) {
    var next = root[name].slice()
    next.push(Math.max(0, Math.min(1, value)))
    while (next.length > historyLimit) next.shift()
    root[name] = next
  }

  function parseStats(line) {
    var parts = String(line || "").trim().split(/\s+/)
    if (parts[0] === "proc" && parts.length >= 4) {
      var next = root.processes.slice()
      var processCpu = Math.max(0, Math.min(100, Number(parts[2]) || 0))
      var processMem = Math.max(0, Math.min(100, Number(parts[3]) || 0))
      next.push({ name: parts[1], cpu: processCpu, mem: processMem })
      root.processes = next.slice(0, 5)
      return
    }
    if (parts.length < 9) return

    var cpuIdle = Number(parts[4]) + Number(parts[5])
    var cpuTotal = 0
    for (var i = 1; i <= 8; i++) cpuTotal += Number(parts[i])

    if (haveCpuBaseline) {
      var totalDelta = cpuTotal - lastCpuTotal
      var idleDelta = cpuIdle - lastCpuIdle
      if (totalDelta > 0) cpuUsage = Math.max(0, Math.min(1, (totalDelta - idleDelta) / totalDelta))
    } else {
      haveCpuBaseline = true
    }

    lastCpuTotal = cpuTotal
    lastCpuIdle = cpuIdle

    var memTotal = Number(parts[9])
    var memAvailable = Number(parts[10])
    if (memTotal > 0) {
      memUsage = Math.max(0, Math.min(1, (memTotal - memAvailable) / memTotal))
      memUsedGb = (memTotal - memAvailable) / 1048576
      memTotalGb = memTotal / 1048576
    }

    load1 = Number(parts[11]) || 0
    load5 = Number(parts[12]) || 0
    load15 = Number(parts[13]) || 0

    pushHistory("cpuHistory", cpuUsage)
    pushHistory("memHistory", memUsage)
  }

  Component.onCompleted: refreshTimer.restart()

  BarIconButton {
    id: button
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: root.vertical ? root.barSize : Style.bar.iconSlot
    height: root.barSize
    bar: root.bar
    text: root.icon
    active: root.busy
    tooltipText: root.tooltip
    onPressed: function(b) {
      if (b === Qt.RightButton && root.bar) root.bar.run("xdg-terminal-exec btop")
      else root.toggle()
    }
    onWheelMoved: function(delta) { root.toggle() }
  }

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    cardRadius: 0
    borderSpec: Border.flat(Color.accent, Style.space(2))
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(380))
    contentHeight: popup.fittedContentHeight(panelColumn.implicitHeight)

    Column {
      id: panelColumn
      anchors.fill: parent
      spacing: Style.space(12)

       // Match the battery panel's compact hero and solid progress strip.
       Item {
         width: parent.width
         implicitHeight: Math.max(monitorIcon.implicitHeight, monitorLabels.implicitHeight, monitorPercent.implicitHeight)

         Text {
           id: monitorIcon
           text: root.icon
           color: root.busy ? Color.accent : root.bar.foreground
           font.family: root.bar.fontFamily
           font.pixelSize: Style.font.display
           anchors.left: parent.left
           anchors.verticalCenter: parent.verticalCenter
         }

         Column {
           id: monitorLabels
           anchors.left: monitorIcon.right
           anchors.leftMargin: Style.space(14)
           anchors.right: monitorPercent.left
           anchors.rightMargin: Style.space(10)
           anchors.verticalCenter: parent.verticalCenter
           spacing: Style.space(2)

           Text {
             width: parent.width
             text: "System monitor"
             color: root.bar.foreground
             font.family: root.bar.fontFamily
             font.pixelSize: Style.font.title
             font.bold: true
             elide: Text.ElideRight
           }

           Text {
             width: parent.width
             text: "SYSTEM LOAD"
             color: Qt.darker(root.bar.foreground, 1.4)
             font.family: root.bar.fontFamily
             font.pixelSize: Style.font.caption
             font.bold: true
             font.letterSpacing: 1.2
             elide: Text.ElideRight
           }
         }

         Text {
           id: monitorPercent
           text: root.percent(root.cpuUsage)
           color: root.bar.foreground
           font.family: root.bar.fontFamily
           font.pixelSize: Style.font.displayLarge
           font.bold: true
           anchors.right: parent.right
           anchors.verticalCenter: parent.verticalCenter
         }
       }

       Item {
         width: parent.width
         implicitHeight: Style.space(8)

         Rectangle {
           anchors.fill: parent
           radius: height / 2
           color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
         }

         Rectangle {
           anchors.left: parent.left
           anchors.verticalCenter: parent.verticalCenter
           width: Math.max(height, parent.width * root.cpuUsage)
           height: parent.height
           radius: height / 2
           color: root.bar.foreground
           opacity: 0.96
           Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
         }
       }

       Item {
         width: parent.width
         implicitHeight: ramLabels.implicitHeight + Style.space(8) + Style.space(5)

         Column {
           id: ramLabels
           width: parent.width
           spacing: Style.space(5)

           Row {
             width: parent.width

             Text {
               width: parent.width - ramValue.implicitWidth
               text: "RAM"
               color: root.bar.foreground
               font.family: root.bar.fontFamily
               font.pixelSize: Style.font.caption
               font.bold: true
             }

             Text {
               id: ramValue
               text: root.percent(root.memUsage) + "  " + root.memUsedGb.toFixed(1) + "/" + root.memTotalGb.toFixed(1) + " GB"
               color: root.bar.foreground
               font.family: root.bar.fontFamily
               font.pixelSize: Style.font.caption
             }
           }

           Item {
             width: parent.width
             height: Style.space(8)

             Rectangle {
               anchors.fill: parent
               radius: height / 2
               color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
             }

             Rectangle {
               anchors.left: parent.left
               anchors.verticalCenter: parent.verticalCenter
               width: Math.max(height, parent.width * root.memUsage)
               height: parent.height
               radius: height / 2
               color: root.bar.foreground
               opacity: 0.96
               Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
             }
           }
         }
       }

       Text {
         text: root.load1.toFixed(2) + "  " + root.load5.toFixed(2) + "  " + root.load15.toFixed(2)
         color: Qt.darker(root.bar.foreground, 1.4)
         font.family: root.bar.fontFamily
         font.pixelSize: Style.font.caption
       }

      Text {
        text: "Top processes"
        color: root.bar.foreground
        opacity: 0.6
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }

      Column {
        width: parent.width
        spacing: Style.space(2)

        Repeater {
          model: root.processes

          Row {
            required property var modelData
            width: parent.width
            height: Style.space(24)
            spacing: Style.space(8)

            Rectangle {
              width: Style.space(3)
              height: parent.height
              color: root.busy ? Color.urgent : Color.accent
            }

            Text {
              width: parent.width - usageText.implicitWidth - Style.space(11)
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.name
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            Text {
              id: usageText
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.cpu.toFixed(1) + "% CPU  " + modelData.mem.toFixed(1) + "% RAM"
              color: root.bar.foreground
              opacity: 0.6
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }

     }
  }

  Process {
    id: statsProc
    command: ["bash", root.statsScript]
    stdout: SplitParser { onRead: function(line) { root.parseStats(line) } }
  }

  Timer {
    id: refreshTimer
    interval: 2000
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  component MetricBlock: Column {
    id: metric

    required property string title
    required property string value
    required property real usage
    required property var history
    required property color accent
    required property color foreground
    required property string fontFamily

    spacing: Style.space(5)
    width: parent.width

    Row {
      width: parent.width

      Text {
        width: parent.width - valueText.implicitWidth
        text: metric.title
        color: metric.foreground
        font.family: metric.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        id: valueText
        text: metric.value
        color: Qt.darker(metric.foreground, 1.25)
        font.family: metric.fontFamily
        font.pixelSize: Style.font.body
      }
    }

    BorderSurface {
      width: parent.width
      height: Style.space(18)
      radius: 0
      color: Util.alpha(metric.foreground, 0.08)
      borderSpec: Border.flat(Util.alpha(metric.foreground, 0.28), 1)

      Row {
        anchors.fill: parent
        anchors.margins: Style.space(3)
        spacing: Style.space(3)

        Repeater {
          model: metric.history

          Rectangle {
            required property real modelData

            width: Math.max(2, (parent.width - (metric.history.length - 1) * Style.space(3)) / Math.max(1, metric.history.length))
            height: Math.max(Style.space(3), parent.height * modelData)
            anchors.bottom: parent.bottom
            radius: 0
            color: Util.alpha(metric.accent, 0.35 + modelData * 0.55)
          }
        }
      }
    }
  }
}

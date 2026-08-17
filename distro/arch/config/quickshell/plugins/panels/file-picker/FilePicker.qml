import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property string fuziPath: Quickshell.env("FUZI_PATH")
  property string currentDirectory: Quickshell.env("HOME")
  property string selectionFile: ""
  property string doneFile: ""
  property string title: "Open file"
  property string filterText: ""
  property string selectedPath: ""
  property string selectedName: ""
  property bool opened: false
  property var entries: []
  property var visibleEntries: []

  onEntriesChanged: updateVisibleEntries()
  onFilterTextChanged: updateVisibleEntries()

  readonly property color foreground: Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.45)
  readonly property color surface: Color.background

  function scriptPath(name) {
    return String(Qt.resolvedUrl(name)).replace(/^file:\/\//, "")
  }

  function open(payload) {
    var args = {}
    try { args = payload ? JSON.parse(payload) || {} : {} } catch (e) {}
    currentDirectory = String(args.directory || Quickshell.env("HOME"))
    selectionFile = String(args.selectionFile || "")
    doneFile = String(args.doneFile || "")
    title = String(args.title || "Open file")
    filterText = ""
    selectedPath = ""
    selectedName = ""
    opened = true
    loadDirectory()
  }

  function close() {
    cancel()
  }

  function loadDirectory() {
    entries = []
    listProcess.command = ["bash", scriptPath("list.sh"), currentDirectory]
    listProcess.running = true
  }

  function appendEntry(line) {
    var parts = String(line || "").split("\t")
    if (parts.length < 3 || !parts[2]) return
    var next = entries.slice()
    next.push({ kind: parts[0], name: parts[1], path: parts[2] })
    entries = next
  }

  function parseRows(rows) {
    String(rows || "").split("\n").forEach(function(row) { root.appendEntry(row) })
  }

  function updateVisibleEntries() {
    if (!filterText) {
      visibleEntries = entries
      return
    }
    var query = filterText.toLowerCase()
    visibleEntries = entries.filter(function(item) {
      return item.name.toLowerCase().indexOf(query) !== -1
    })
  }

  function choose(item) {
    if (!item) return
    if (String(item.kind).toUpperCase() === "D") {
      currentDirectory = item.path
      selectedPath = ""
      selectedName = ""
      loadDirectory()
      return
    }
    selectedPath = item.path
    selectedName = item.name
  }

  function finish() {
    if (!selectedPath) return
    finishProcess.command = ["bash", scriptPath("finish.sh"), selectedPath, selectionFile, doneFile]
    finishProcess.running = true
    opened = false
  }

  function cancel() {
    if (doneFile) {
      cancelProcess.command = ["bash", scriptPath("finish.sh"), "", "", doneFile]
      cancelProcess.running = true
    }
    opened = false
  }

  Process {
    id: listProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseRows(text)
    }
  }

  Process { id: finishProcess }
  Process { id: cancelProcess }

  PanelWindow {
    id: window
    visible: root.opened
    implicitWidth: 1
    implicitHeight: 1
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "fuzi-file-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      z: -1
      color: Util.alpha(Color.background, 0.82)
    }

    MouseArea { anchors.fill: parent; z: -1; onClicked: root.cancel() }

    BorderSurface {
      id: card
      width: Math.min(parent.width - Style.space(32), Style.space(680))
      height: Math.min(parent.height - Style.space(32), Style.space(560))
      anchors.centerIn: parent
      z: 1
      color: root.surface
      borderSpec: Border.flat(root.foreground, Style.space(1))
      radius: 0

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.margins: Style.space(20)
        spacing: Style.space(12)

        Row {
          width: parent.width
          Text {
            width: parent.width - cancelButton.implicitWidth
            text: root.title
            color: root.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Button {
            id: cancelButton
            iconText: "󰅖"
            foreground: root.foreground
            tooltipText: "Cancel"
            onClicked: root.cancel()
          }
        }

        Text {
          width: parent.width
          text: root.currentDirectory
          color: root.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideMiddle
        }

        TextField {
          id: searchField
          width: parent.width
          placeholderText: Style.searchPlaceholder
          text: root.filterText
          foreground: root.foreground
          onTextChanged: root.filterText = text
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) root.cancel()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.finish()
            else if (event.key === Qt.Key_Down) { fileList.forceActiveFocus(); event.accepted = true }
          }
        }

        ListView {
          id: fileList
          width: parent.width
          height: parent.height - 150
          clip: true
          focus: true
          model: root.visibleEntries
          delegate: BorderSurface {
            required property var modelData
            width: fileList.width
            height: Style.space(38)
            color: modelData.path === root.selectedPath ? Util.alpha(root.foreground, 0.14) : "transparent"
            borderSpec: Border.none()

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              spacing: Style.space(10)
              Text {
                text: String(modelData.kind).toUpperCase() === "D" ? "󰉋" : "󰈙"
                color: root.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: modelData.name
                color: root.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
                width: parent.width - Style.space(42)
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                root.choose(modelData)
                if (String(modelData.kind).toUpperCase() !== "D") root.finish()
              }
              onDoubleClicked: if (String(modelData.kind).toUpperCase() !== "D") root.finish()
            }
          }
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) root.cancel()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.finish()
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          Text {
            width: parent.width - openButton.implicitWidth - Style.space(8)
            text: root.selectedName || "Select a file"
            color: root.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
            anchors.verticalCenter: parent.verticalCenter
          }
          Button {
            id: openButton
            iconText: "󰐕"
            text: "Open"
            foreground: root.foreground
            enabled: root.selectedPath !== ""
            onClicked: root.finish()
          }
        }
      }
    }
  }
}

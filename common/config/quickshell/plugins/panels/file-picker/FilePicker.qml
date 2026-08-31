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
  property int selectedIndex: -1
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
    selectedIndex = -1
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
      selectedIndex = -1
      return
    }
    var query = filterText.toLowerCase()
    visibleEntries = entries.filter(function(item) {
      return item.name.toLowerCase().indexOf(query) !== -1
    })
    selectedIndex = -1
  }

  function moveSelection(delta) {
    if (visibleEntries.length === 0) return
    selectedIndex = Math.max(0, Math.min(visibleEntries.length - 1,
      selectedIndex < 0 ? (delta > 0 ? 0 : visibleEntries.length - 1) : selectedIndex + delta))
    choose(visibleEntries[selectedIndex])
  }

  function activateSelection() {
    if (selectedIndex < 0 || selectedIndex >= visibleEntries.length) return
    var entry = visibleEntries[selectedIndex]
    if (String(entry.kind).toUpperCase() === "D") choose(entry)
    else finish()
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
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.margins: Style.spacing.popupPadding
        spacing: Style.space(14)

        Item {
          id: hero
          width: parent.width
          implicitHeight: Math.max(pickerIcon.implicitHeight, pickerLabels.implicitHeight)

          Text {
            id: pickerIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰉋"
            color: root.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.display
          }

          Column {
            id: pickerLabels
            anchors.left: pickerIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: root.title
              color: root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: root.currentDirectory
              color: root.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideMiddle
            }
          }
        }

        PanelSeparator { id: separatorTop; foreground: root.foreground }

        TextField {
          id: searchField
          width: parent.width
          placeholderText: Style.searchPlaceholder
          text: root.filterText
          foreground: root.foreground
          onTextChanged: root.filterText = text
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) root.cancel()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activateSelection()
            else if (event.key === Qt.Key_Down) { root.moveSelection(1); fileList.forceActiveFocus(); event.accepted = true }
          }
        }

        PanelSectionHeader {
          id: filesHeader
          text: "FILES"
          foreground: root.foreground
        }

        ListView {
          id: fileList
          width: parent.width
          height: Math.max(Style.space(120), parent.height - hero.implicitHeight
            - searchField.implicitHeight - filesHeader.implicitHeight - footer.implicitHeight
            - separatorTop.implicitHeight - separatorBottom.implicitHeight - Style.space(84))
          clip: true
          focus: true
          model: root.visibleEntries
          delegate: CursorSurface {
            required property var modelData
            required property int index
            width: fileList.width
            implicitHeight: Style.space(38)
            hasCursor: index === root.selectedIndex
            current: modelData.path === root.selectedPath
            foreground: root.foreground

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
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
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: if (containsMouse) root.selectedIndex = index
              onClicked: {
                root.choose(modelData)
              }
              onDoubleClicked: root.activateSelection()
            }
          }
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) root.cancel()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activateSelection()
            else if (event.key === Qt.Key_Up) { root.moveSelection(-1); event.accepted = true }
            else if (event.key === Qt.Key_Down) { root.moveSelection(1); event.accepted = true }
          }
        }

        PanelSeparator { id: separatorBottom; foreground: root.foreground }

        Row {
          id: footer
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
            bordered: true
            onClicked: if (root.selectedPath) root.finish()
          }
        }
      }
    }
  }
}

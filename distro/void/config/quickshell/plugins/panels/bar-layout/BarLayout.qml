import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root
  property var shell: null
  property bool opened: false
  property var sections: []
  property string position: "top"

  function entryId(entry) { return typeof entry === "string" ? entry : (entry && entry.id ? String(entry.id) : "") }
  function label(id) {
    var names = ({"fuzi.workspaces":"Workspaces", "fuzi.weather":"Weather", "fuzi.clock":"Clock", "fuzi.media":"Media", "fuzi.keyboard-layout":"Keyboard", "fuzi.bluetooth":"Bluetooth", "fuzi.network":"Network", "fuzi.tray":"Tray", "fuzi.audio":"Audio", "fuzi.system-monitor":"System monitor", "fuzi.power":"Power", "fuzi.dnd":"Do not disturb"})
    return names[id] || id.replace(/^fuzi\./, "")
  }
  function readLayout() {
    var layout = shell && shell.shellConfig && shell.shellConfig.bar ? shell.shellConfig.bar.layout : {}
    position = shell && shell.shellConfig && shell.shellConfig.bar && shell.shellConfig.bar.position
      ? String(shell.shellConfig.bar.position) : "top"
    sections = [
      { id:"left", title:"Left", entries:Array.isArray(layout.left) ? layout.left.slice() : [] },
      { id:"center", title:"Center", entries:Array.isArray(layout.center) ? layout.center.slice() : [] },
      { id:"right", title:"Right", entries:Array.isArray(layout.right) ? layout.right.slice() : [] }
    ]
  }
  function open() { readLayout(); opened = true }
  function close() { opened = false }
  function copySections() { return sections.map(function(s) { return { id:s.id, title:s.title, entries:s.entries.slice() } }) }
  function save(next) {
    sections = next
    if (shell && shell.mutateShellConfig) shell.mutateShellConfig(function(config) { config.bar.layout = {left:next[0].entries, center:next[1].entries, right:next[2].entries} })
  }
  function move(sectionIndex, itemIndex, delta) {
    var next = copySections(), list = next[sectionIndex].entries, target = itemIndex + delta
    if (target < 0 || target >= list.length) return
    var value = list[itemIndex]; list[itemIndex] = list[target]; list[target] = value; save(next)
  }
  function transfer(sectionIndex, itemIndex, direction) {
    var next = copySections(), target = sectionIndex + direction
    if (target < 0 || target >= next.length) return
    var value = next[sectionIndex].entries.splice(itemIndex, 1)[0]
    if (value) { next[target].entries.push(value); save(next) }
  }
  function setPosition(position) {
    root.position = position
    if (!shell || !shell.mutateShellConfig) return
    shell.mutateShellConfig(function(config) {
      if (!config.bar) config.bar = {}
      config.bar.position = position
    })
  }

  component LayoutPill: Button {
    required property string label
    text: label
    foreground: Color.foreground
    fontFamily: Style.font.family
    fontSize: Style.font.bodySmall
    horizontalPadding: Style.spacing.controlPaddingX
    verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
    bordered: true
    active: root.position === label.toLowerCase()
  }

  PanelWindow {
    visible: root.opened
    anchors { top:true; bottom:true; left:true; right:true }
    color: "transparent"
    WlrLayershell.namespace: "fuzi-bar-layout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill:parent; color:Util.alpha(Color.background, 0.78) }
    MouseArea { anchors.fill:parent; onClicked:root.close() }
    Item {
      anchors.fill: parent
      focus: root.opened
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        }
      }
    }

    BorderSurface {
      id: card; z:1; width:Math.min(parent.width - Style.space(32), Style.space(900)); height:Math.min(parent.height - Style.space(32), Style.space(600)); anchors.centerIn:parent
      color:Color.background; borderSpec:Border.flat(Color.accent, Style.space(2)); radius:0
      MouseArea { anchors.fill:parent; onClicked:{} }
      Column {
        anchors.fill:parent; anchors.margins:Style.space(20); spacing:Style.space(14)
         Row {
           width:parent.width
           spacing:Style.space(14)
           Text { text:"󰍜"; color:Color.foreground; font.family:Style.font.family; font.pixelSize:Style.font.display; anchors.verticalCenter:parent.verticalCenter }
           Column {
             anchors.verticalCenter:parent.verticalCenter
             spacing:0
             Text { text:"Bar layout"; color:Color.foreground; font.family:Style.font.family; font.pixelSize:Style.font.title; font.bold:true }
             Text { text:"Arrange widgets"; color:Qt.darker(Color.foreground, 1.4); font.family:Style.font.family; font.pixelSize:Style.font.caption }
           }
         }
         Row {
           width:parent.width; spacing:Style.space(6)
           Text { text:"Bar position"; color:Color.foreground; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall; anchors.verticalCenter:parent.verticalCenter }
           LayoutPill { label:"Top"; onClicked:root.setPosition("top") }
           LayoutPill { label:"Bottom"; onClicked:root.setPosition("bottom") }
           LayoutPill { label:"Left"; onClicked:root.setPosition("left") }
           LayoutPill { label:"Right"; onClicked:root.setPosition("right") }
        }
        Row {
          width:parent.width; height:parent.height - 108; spacing:Style.space(12)
          Repeater {
            model:root.sections
            BorderSurface {
              id: sectionCard
              required property var modelData
              required property int index
              property int sectionIndex:index
              width:(parent.width - Style.space(24)) / 3; height:parent.height; color:Util.alpha(Color.accent, 0.04); borderSpec:Border.flat(Util.alpha(Color.accent, 0.55), Style.space(2)); radius:0
              Column {
                anchors.fill:parent; anchors.margins:Style.space(10); spacing:Style.space(8)
                 Row {
                   width:parent.width
                   spacing:Style.space(8)
                   Text { text:modelData.id === "left" ? "󰁝" : modelData.id === "center" ? "󰘶" : "󰁅"; color:Color.foreground; font.family:Style.font.family; font.pixelSize:Style.font.subtitle; anchors.verticalCenter:parent.verticalCenter }
                   Text { text:modelData.title; color:Color.foreground; font.family:Style.font.family; font.pixelSize:Style.font.subtitle; font.bold:true; anchors.verticalCenter:parent.verticalCenter }
                 }
                ListView {
                  width:parent.width; height:parent.height - 35; clip:true; model:modelData.entries
                  delegate: BorderSurface {
                    required property var modelData
                    required property int index
                     width:parent.width; height:Style.space(36); color:"transparent"; borderSpec:Border.none()
                     Row {
                       anchors.fill:parent; spacing:Style.space(3)
                       Text {
                         id: moduleButton
                         width:parent.width-upButton.implicitWidth-downButton.implicitWidth-leftButton.implicitWidth-rightButton.implicitWidth-Style.space(12)
                         height:parent.height
                         text:root.label(root.entryId(modelData))
                         color:Color.foreground
                         font.family:Style.font.family
                         font.pixelSize:Style.font.bodySmall
                         leftPadding:Style.spacing.controlPaddingX
                         verticalAlignment:Text.AlignVCenter
                         elide:Text.ElideRight
                       }
                       Button { id:upButton; iconText:"󰁝"; tooltipText:"Move up"; foreground:Color.foreground; onClicked:root.move(sectionCard.sectionIndex, index, -1) }
                      Button { id:downButton; iconText:"󰁅"; tooltipText:"Move down"; foreground:Color.foreground; onClicked:root.move(sectionCard.sectionIndex, index, 1) }
                      Button { id:leftButton; iconText:"󰁍"; tooltipText:"Previous section"; foreground:Color.foreground; visible:sectionCard.sectionIndex > 0; onClicked:root.transfer(sectionCard.sectionIndex, index, -1) }
                      Button { id:rightButton; iconText:"󰁔"; tooltipText:"Next section"; foreground:Color.foreground; visible:sectionCard.sectionIndex < 2; onClicked:root.transfer(sectionCard.sectionIndex, index, 1) }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

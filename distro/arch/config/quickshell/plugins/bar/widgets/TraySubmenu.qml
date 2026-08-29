import Quickshell
import QtQuick
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Ui

// A cascading submenu, opened to the side of the TrayMenuRow that hosts it.
// Renders with TrayMenuRow itself, so a row inside here that itself
// hasChildren opens another one of these — nesting goes as deep as the
// DBusMenu tree does. See TrayMenuRow.qml for why this lives in its own
// file rather than as an inline `component`.
PopupWindow {
  id: subRoot
  required property QtObject ownerRoot
  required property Item anchorItem
  required property var menuEntry
  required property real rowWidth
  readonly property bool pointerInside: subHover.hovered
  property bool open: false

  visible: open
  color: "transparent"
  implicitWidth: subRoot.rowWidth
  implicitHeight: subCard.contentHeightHint

  Component.onCompleted: subRoot.ownerRoot.registerSubmenuWindow(subRoot)
  Component.onDestruction: subRoot.ownerRoot.unregisterSubmenuWindow(subRoot)

  readonly property var anchorWindow: anchorItem && anchorItem.QsWindow ? anchorItem.QsWindow.window : null
  // TrayMenuRow lives directly in the menu column's local coordinate space.
  // PopupWindow anchors use that same space for `rect`, so mapping through a
  // window contentItem would apply the popup's offset for a second time.
  readonly property real anchorX: anchorItem ? Math.round(anchorItem.x - 2) : 0
  readonly property real anchorY: anchorItem ? Math.round(anchorItem.y) : 0

  anchor {
    window: subRoot.anchorWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Left
    rect.x: subRoot.anchorX
    rect.y: subRoot.anchorY
    rect.width: 1
    rect.height: 1
  }

  QsMenuOpener {
    id: subOpener
    menu: subRoot.menuEntry
  }

  BorderSurface {
    id: subCard
    anchors.fill: parent
    color: Color.popups.background
    borderSpec: Border.localOrSurfaceSpec("popups", "border", Color.popups.border, Color.popups.border, Math.max(1, Style.space(2)))
    padding: Style.space(8)
    radius: Style.cornerRadius

    readonly property real contentHeightHint: subColumn.implicitHeight + padding * 2

    Column {
      id: subColumn
      width: subRoot.rowWidth - Style.space(16)
      x: Style.space(8)
      y: Style.space(8)
      spacing: 0

      Repeater {
        model: subOpener.children
        delegate: TrayMenuRow {
          rowWidth: subColumn.width
          ownerRoot: subRoot.ownerRoot
          applyTitleDedup: false
        }
      }
    }
  }

  HoverHandler {
    id: subHover
  }
}

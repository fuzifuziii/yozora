import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fuzi.mihomo"

  property bool opened: false
  property bool online: false
  property string version: ""
  property string mode: "rule"
  property bool tunEnabled: false
  property string currentProxy: "DIRECT"
  property var proxies: []
  property var proxyGroups: []
  property var providers: []
  property var proxyLatencies: ({})
  property string groupLatency: ""
  property string apiUrl: "http://127.0.0.1:9090"
  property string selectedGroup: "Proxy"
  property string actionKind: ""
  property string latencyTarget: ""
  property string subscriptionUrl: ""
  property string actionStatus: ""
  readonly property string adminScript: Quickshell.env("FUZI_PATH") + "/bin/fuzi-mihomo-admin"

  readonly property string statusText: online
    ? "Mihomo · " + mode + " · " + currentProxy
    : "Mihomo · offline"
  readonly property bool tunneled: online && currentProxy !== "DIRECT"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }
  function closeForPopoutSwitch() { close() }

  function refresh() {
    versionProc.running = false
    configProc.running = false
    proxiesProc.running = false
    providersProc.running = false
    versionProc.running = true
    configProc.running = true
    proxiesProc.running = true
    providersProc.running = true
  }

  function setMode(nextMode) {
    actionProc.command = ["curl", "-sS", "-X", "PATCH", apiUrl + "/configs",
      "-H", "Content-Type: application/json", "--data-raw", JSON.stringify({ mode: nextMode })]
    actionProc.running = true
  }

  function setTun(enabled) {
    actionKind = "tun"
    actionStatus = "Requesting root permission..."
    actionProc.command = ["pkexec", adminScript, "tun", enabled ? "on" : "off"]
    actionProc.running = true
  }

  function setSubscriptionUrl(url) {
    if (!url) return
    actionKind = "url"
    actionStatus = "Requesting root permission..."
    actionProc.command = ["pkexec", adminScript, "url", url]
    actionProc.running = true
  }

  function selectProxy(name) {
    actionProc.command = ["curl", "-sS", "-X", "PUT", apiUrl + "/proxies/" + encodeURIComponent(selectedGroup),
      "-H", "Content-Type: application/json", "--data-raw", JSON.stringify({ name: name })]
    actionProc.running = true
  }

  function parseConfig(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      mode = String(data.mode || "rule")
      tunEnabled = data.tun && data.tun.enable === true
      online = true
    } catch (e) {
      online = false
    }
  }

  function parseProxies(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      var allGroups = data.proxies || {}
      var nextGroups = []
      for (var name in allGroups) {
        var candidate = allGroups[name]
        if (candidate && ["Selector", "URLTest", "Fallback", "LoadBalance"].indexOf(candidate.type) !== -1)
          nextGroups.push(String(name))
      }
      proxyGroups = nextGroups.length > 0 ? nextGroups : ["Proxy"]
      if (proxyGroups.indexOf(selectedGroup) === -1) selectedGroup = proxyGroups[0]
      var group = allGroups[selectedGroup]
      if (!group) { proxies = []; currentProxy = "DIRECT"; return }
      currentProxy = String(group.now || "DIRECT")
      proxies = Array.isArray(group.all) ? group.all.slice() : []
      online = true
    } catch (e) {
      online = false
    }
  }

  function selectGroup(name) {
    selectedGroup = name
    proxiesProc.running = false
    proxiesProc.running = true
  }

  function updateProvider(name) {
    actionKind = "provider"
    actionStatus = "Updating provider..."
    actionProc.command = ["curl", "-sS", "-X", "PUT", apiUrl + "/providers/proxies/" + encodeURIComponent(name)]
    actionProc.running = true
  }

  function testProxy(name) {
    actionKind = "delay"
    latencyTarget = name
    actionProc.command = ["curl", "-sS", "--max-time", "7", apiUrl + "/proxies/" + encodeURIComponent(selectedGroup) + "/delay?url=https%3A%2F%2Fwww.gstatic.com%2Fgenerate_204&timeout=5000"]
    actionProc.running = true
  }

  function parseDelay(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      if (data.delay !== undefined) {
        groupLatency = String(data.delay) + " ms"
        return
      }
      var next = {}
      for (var key in proxyLatencies) next[key] = proxyLatencies[key]
      next[latencyTarget] = data.delay !== undefined ? String(data.delay) + " ms" : "error"
      proxyLatencies = next
    } catch (e) {
      var failed = {}
      for (var oldKey in proxyLatencies) failed[oldKey] = proxyLatencies[oldKey]
      failed[latencyTarget] = "error"
      proxyLatencies = failed
    }
  }

  Component.onCompleted: refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    text: "󰖂"
    active: root.tunneled
    tooltipText: root.statusText
    onPressed: function(mouseButton) { root.toggle() }
    onWheelMoved: function(delta) { root.toggle() }
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

      Column {
        width: parent.width
        spacing: 0

        Row {
          width: parent.width
          spacing: Style.space(10)
          Text {
            id: mihomoIcon
            text: "󰖂"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            opacity: root.online ? 1.0 : 0.5
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            width: parent.width - mihomoIcon.implicitWidth - refreshButton.implicitWidth - Style.space(20)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
              width: parent.width
              text: root.online ? "Mihomo" : "Mihomo offline"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.online ? "Version " + root.version : "API unavailable"
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
      }

      Text {
        visible: !root.online
        text: "Apply a subscription URL to initialize Mihomo"
        color: Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        width: parent.width
      }

      Text {
        visible: root.actionStatus !== ""
        text: root.actionStatus
        color: root.actionStatus.indexOf("failed") !== -1 || root.actionStatus.indexOf("Error") !== -1
          ? Color.urgent : Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        width: parent.width
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
          enabled: subscriptionField.text.indexOf("http") === 0
          onClicked: root.setSubscriptionUrl(subscriptionField.text)
        }
      }

      Flow {
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          model: ["rule", "global", "direct"]
          MihomoPill {
            required property string modelData
            label: modelData.toUpperCase()
            selected: root.mode === modelData
            onClicked: root.setMode(modelData)
          }
        }
      }

      Flow {
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          model: root.proxyGroups
          MihomoPill {
            required property string modelData
            label: modelData
            selected: root.selectedGroup === modelData
            onClicked: root.selectGroup(modelData)
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)
        Text {
          text: "TUN"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
        ToggleSwitch {
          checked: root.tunEnabled
          foreground: root.bar.foreground
          onToggled: root.setTun(!root.tunEnabled)

          PanelToolTip {
            visible: parent.containsMouse
            text: root.tunEnabled ? "Turn TUN off" : "Turn TUN on"
            fontFamily: root.bar.fontFamily
          }
        }
      }

      PanelSeparator { foreground: root.bar.foreground }

      Row {
        width: parent.width
        Text {
          width: parent.width - groupPingButton.implicitWidth
          text: root.selectedGroup + " · " + root.currentProxy
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
        Button {
          id: groupPingButton
          iconText: "󰄰"
          foreground: root.bar.foreground
          tooltipText: "Ping: " + (root.groupLatency || "not tested")
          onClicked: root.testProxy(root.selectedGroup)
        }
      }

      ListView {
        id: proxyList
        width: parent.width
        height: Math.min(Style.space(260), Math.max(0, root.proxies.length * Style.space(36)))
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.proxies
        delegate: MihomoPill {
          required property string modelData
          width: proxyList.width
          height: Style.space(36)
          label: modelData
          leftAlign: true
          selected: modelData === root.currentProxy
          onClicked: root.selectProxy(modelData)
        }
      }

      Text {
        visible: root.online && root.proxies.length === 0
        text: "No proxies in group"
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }

      Column {
        visible: root.online && root.providers.length > 0
        width: parent.width
        spacing: Style.space(3)
        Repeater {
          model: root.providers
          Row {
            required property string modelData
            width: parent.width
            Text {
              width: parent.width - updateButton.implicitWidth
              text: "Provider · " + modelData
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }
            Button {
              id: updateButton
              iconText: "󰑐"
              foreground: root.bar.foreground
              tooltipText: "Update provider"
              onClicked: root.updateProvider(modelData)
            }
          }
        }
      }
    }
  }

  // Shared bordered control used for mode, group, and proxy selection. This
  // follows Network's BandPill/DnsProviderPill visual contract.
  component MihomoPill: Button {
    id: pill
    required property string label

    text: label
    fontSize: Style.font.bodySmall
    foreground: root.bar.foreground
    fontFamily: root.bar.fontFamily
    horizontalPadding: Style.spacing.controlPaddingX
    verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
    bordered: true
    tooltipText: label
  }

  Process {
    id: versionProc
    command: ["curl", "-sS", "--max-time", "2", root.apiUrl + "/version"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.version = String(JSON.parse(String(text || "{}")).version || "") } catch (e) { root.version = "" }
      }
    }
    onExited: function(code) { if (code !== 0) root.online = false }
  }

  Process {
    id: configProc
    command: ["curl", "-sS", "--max-time", "2", root.apiUrl + "/configs"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseConfig(text) }
    onExited: function(code) { if (code !== 0) root.online = false }
  }

  Process {
    id: proxiesProc
    command: ["curl", "-sS", "--max-time", "2", root.apiUrl + "/proxies"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseProxies(text) }
    onExited: function(code) { if (code !== 0) root.online = false }
  }

  Process {
    id: providersProc
    command: ["curl", "-sS", "--max-time", "2", root.apiUrl + "/providers/proxies"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(String(text || "{}"))
          var names = []
          for (var name in (data.providers || {})) names.push(name)
          root.providers = names
        } catch (e) { root.providers = [] }
      }
    }
  }

  Process {
    id: actionProc
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") root.actionStatus = String(text).trim()
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (root.actionKind === "delay") root.parseDelay(text)
    }
    onExited: function(code) {
      if (code === 0) root.actionStatus = root.actionKind === "tun" ? "TUN configuration applied" : "Done"
      else if (!root.actionStatus) root.actionStatus = "Action failed"
      if (root.actionKind !== "delay") root.refresh()
      root.actionKind = ""
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: if (!versionProc.running && !configProc.running && !proxiesProc.running && !providersProc.running) root.refresh()
  }
}

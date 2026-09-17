import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
BarWidget {
  id: root
  moduleName: "ai-usage"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ── Panel lifecycle (makes this discoverable as a panel widget) ──
  property bool opened: false
  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }

  // ── State ──────────────────────────────────────────────────────
  property var entries: []
  property var primaryEntry: null
  property string barText: "—"
  property bool stale: false
  property int activeTab: 0

  // ── Settings ───────────────────────────────────────────────────
  readonly property int refreshMs: setting("refresh_minutes", 5) * 60 * 1000
  readonly property string vendor: setting("vendor", "auto")
  readonly property bool showCountdown: setting("show_countdown", true)
  readonly property bool showIcon: setting("show_icon", true)

  // ── Helpers ────────────────────────────────────────────────────

  function severityRank(s) {
    switch (s) {
      case "critical": return 3; case "high": return 2
      case "mid": return 1; case "low": return 0; default: return -1
    }
  }

  function severityColor(s) {
    switch (s) {
      case "critical": return Color.urgent; case "high": return "#e0a040"
      case "mid": return "#c0c040"; default: return Color.foreground
    }
  }

  function iconFor(id) {
    var icons = { "anthropic": "★", "openai": "◉", "zai": "⚡", "openrouter": "◇",
      "deepseek": "🐟", "kimi": "🌙", "grok": "✕", "antigravity": "✨",
      "cursor": "↖", "kiro": "👻" }
    return icons[id] || "🧠"
  }

  function formatCountdown(resetAt) {
    if (!resetAt) return ""
    var diff = Math.max(0, (new Date(resetAt).getTime() - Date.now()) / 1000)
    if (diff <= 0) return "now"
    if (diff >= 86400) return Math.floor(diff / 86400) + "d " + Math.floor((diff % 86400) / 3600) + "h"
    var h = Math.floor(diff / 3600), m = Math.floor((diff % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }

  function pickBusiest() {
    var candidates = entries.filter(function(e) { return e.status !== "error" })
    if (candidates.length === 0) return null
    if (vendor !== "auto") {
      for (var i = 0; i < candidates.length; i++)
        if (candidates[i].id === vendor) return candidates[i]
    }
    candidates.sort(function(a, b) {
      var sa = severityRank(a.metrics && a.metrics[0] ? a.metrics[0].severity : "low")
      var sb = severityRank(b.metrics && b.metrics[0] ? b.metrics[0].severity : "low")
      if (sa !== sb) return sb - sa
      return (b.metrics && b.metrics[0] ? b.metrics[0].percent : 0) -
             (a.metrics && a.metrics[0] ? a.metrics[0].percent : 0)
    })
    return candidates[0]
  }

  function updateDisplay() {
    primaryEntry = pickBusiest()
    if (primaryEntry) {
      var m = primaryEntry.metrics && primaryEntry.metrics[0]
      barText = (showIcon ? iconFor(primaryEntry.id) + " " : "") + (m ? m.percent + "%" : "—")
      if (showCountdown && m) barText += " " + formatCountdown(m.reset_at)
    } else {
      barText = "—"
    }
    if (activeTab > entries.length) activeTab = 0
  }

  // ── Refresh ───────────────────────────────────────────────────

  function refresh() { if (!proc.running) proc.running = true }

  Process {
    id: proc
    command: ["ai-usagebar", "usage", "--json"]
    onRunningChanged: { if (running) stallTimer.restart(); else stallTimer.stop() }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { var d = JSON.parse(text || "{}"); root.entries = d.entries || []; root.stale = false; root.updateDisplay() }
        catch (e) { root.stale = true }
      }
    }
  }

  Timer { id: refreshTimer; interval: root.refreshMs; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { id: stallTimer; interval: 15000; onTriggered: { proc.running = false; refreshTimer.restart() } }
  Component.onCompleted: root.refresh()

  // ── Bar button ─────────────────────────────────────────────────

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: "AI Usage — click for details"
    onPressed: function(b) { if (b !== Qt.RightButton) root.toggle() }
  }

  // ── Popup panel ────────────────────────────────────────────────

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(panelContent.implicitHeight, Style.space(560))

    Column {
      id: panelContent
      width: parent.width
      spacing: Style.spacing.md

      // ── Tab bar ──────────────────────────────────────────
      Row {
        width: parent.width; spacing: Style.spacing.xs

        Repeater {
          model: [{id:"",label:"Overview"}].concat(
            root.entries.filter(function(e){return e.status!=="error"}).map(function(e,i){
              return {id:e.id,label:root.iconFor(e.id)+" "+(e.short_name||e.id),idx:i}
            })
          )
          delegate: Rectangle {
            height: tl.implicitHeight + Style.space(8)
            width: Math.min(tl.implicitWidth + Style.space(16), Style.space(100))
            radius: Style.cornerRadius > 0 ? Style.cornerRadius : 4
            color: root.activeTab === index ? Style.selectedFillFor(Color.foreground, Color.accent, Color.urgent) : "transparent"
            border { width: 1; color: root.activeTab === index ? Style.selectedBorderFor(Color.foreground, Color.accent, Color.urgent) : Style.normalBorderFor(Color.foreground, Color.accent, Color.urgent) }
            Text {
              id: tl; anchors.centerIn: parent
              text: modelData.label; color: Color.foreground
              font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: root.activeTab === index
              elide: Text.ElideRight
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.activeTab = index }
          }
        }
      }

      PanelSeparator { foreground: Color.foreground }

      // ── Overview ───────────────────────────────────────
      Column {
        visible: root.activeTab === 0; width: parent.width; spacing: Style.spacing.sm

        Repeater {
          model: root.entries
          delegate: Column {
            width: parent.width; spacing: Style.spacing.xxs
            Row {
              width: parent.width; spacing: Style.spacing.sm
              Text { text: root.iconFor(modelData.id) + " " + (modelData.display_name||modelData.id); color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; width: Style.space(130); elide: Text.ElideRight }
              Item { width: Style.spacing.md; height: 1 }
              Text { text: modelData.status==="error" ? "⚠ error" : (modelData.metrics&&modelData.metrics[0]?modelData.metrics[0].percent+"%":"—"); color: modelData.status==="error" ? Color.urgent : severityColor(modelData.metrics&&modelData.metrics[0]?modelData.metrics[0].severity:"low"); font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true }
              Text { visible: modelData.status!=="error"&&modelData.metrics&&modelData.metrics[0]; text: modelData.metrics&&modelData.metrics[0]?root.formatCountdown(modelData.metrics[0].reset_at):""; color: Qt.darker(Color.foreground,1.3); font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
            }
            Text { visible: modelData.plan&&modelData.plan.length>0&&modelData.status!=="error"; text: modelData.plan||""; color: Qt.darker(Color.foreground,1.4); font.family: Style.font.family; font.pixelSize: Style.font.caption; leftPadding: Style.space(18) }
            Text { visible: modelData.status==="error"&&modelData.error; text: modelData.error||""; color: Color.urgent; font.family: Style.font.family; font.pixelSize: Style.font.caption; leftPadding: Style.space(18); width: parent.width-Style.space(18); wrapMode: Text.WordWrap; elide: Text.ElideRight; maximumLineCount: 2 }
            Repeater {
              model: modelData.metrics ? modelData.metrics.slice(1) : []
              delegate: Row {
                leftPadding: Style.space(18); spacing: Style.spacing.sm
                Text { text: modelData.label||""; color: Qt.darker(Color.foreground,1.4); font.family: Style.font.family; font.pixelSize: Style.font.caption; width: Style.space(90); elide: Text.ElideRight }
                Text { text: modelData.percent+"%"; color: severityColor(modelData.severity); font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
                Text { text: root.formatCountdown(modelData.reset_at); color: Qt.darker(Color.foreground,1.3); font.family: Style.font.family; font.pixelSize: Style.font.caption }
              }
            }
            Item { width: 1; height: Style.spacing.sm; visible: index < root.entries.length-1 }
          }
        }
        Text { visible: root.entries.length===0; text: "No providers configured.\n\nRun ai-usagebar to set up\nproviders in\n~/.config/ai-usagebar/config.toml"; color: Qt.darker(Color.foreground,1.3); font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; width: parent.width; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
      }

      // ── Per-provider detail ──────────────────────────────
      Column {
        visible: root.activeTab > 0; width: parent.width; spacing: Style.spacing.md

        Repeater {
          model: root.entries.filter(function(e){return e.status!=="error"})
          delegate: Column {
            visible: root.activeTab === index+1; width: parent.width; spacing: Style.spacing.sm
            PanelHero {
              width: parent.width; foreground: Color.foreground; fontFamily: Style.font.family
              title: root.iconFor(modelData.id)+" "+(modelData.display_name||modelData.id)
              meta: modelData.plan||""; detail: modelData.status==="ready"?"active":modelData.status
            }
            PanelSeparator { foreground: Color.foreground }
            Repeater {
              model: modelData.metrics||[]
              delegate: Column {
                width: parent.width; spacing: Style.spacing.xxs
                Row {
                  width: parent.width; spacing: Style.spacing.sm
                  Text { text: modelData.label||"Metric"; color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body; width: Style.space(130); elide: Text.ElideRight }
                  Text { text: modelData.percent+"%"; color: severityColor(modelData.severity); font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true }
                  Text { text: root.formatCountdown(modelData.reset_at); color: Qt.darker(Color.foreground,1.3); font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
                }
                Rectangle {
                  width: parent.width; height: Style.space(4); radius: 2
                  color: Qt.rgba(Color.foreground.r,Color.foreground.g,Color.foreground.b,0.08)
                  Rectangle { width: Math.max(0,Math.min(parent.width,parent.width*modelData.percent/100)); height: parent.height; radius: 2; color: severityColor(modelData.severity) }
                }
                Text { text: modelData.detail||""; visible: modelData.detail&&modelData.detail.length>0; color: Qt.darker(Color.foreground,1.4); font.family: Style.font.family; font.pixelSize: Style.font.caption; width: parent.width; wrapMode: Text.WordWrap }
                Item { width: 1; height: Style.spacing.sm; visible: index < (modelData.metrics?modelData.metrics.length-1:0) }
              }
            }
          }
        }
      }
    }
  }
}
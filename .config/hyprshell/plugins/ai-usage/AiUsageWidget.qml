import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// AI plan usage in the bar, backed by the `ai-usagebar` CLI. Click opens a
// popup with per-provider detail; right-click on the bar icon or the
// refresh button in the popup header re-run the CLI immediately instead of
// waiting for the timer.
BarWidget {
  id: root
  moduleName: "ai-usage"

  // ── Panel lifecycle (bar host's contract for popout coordination) ──
  property bool popupOpen: false
  readonly property bool opened: popupOpen
  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  // ── State ──────────────────────────────────────────────────────
  property var entries: []
  property var primaryEntry: null
  property bool stale: false
  property string activeTabId: ""

  // ── Settings ───────────────────────────────────────────────────
  readonly property int refreshMs: setting("refresh_minutes", 5) * 60 * 1000
  readonly property string vendorSetting: setting("vendor", "auto")
  readonly property bool showCountdown: setting("show_countdown", true)
  readonly property bool showIcon: setting("show_icon", true)

  // ── Icons — JetBrainsMono Nerd Font / Material Design Icons subset ──
  readonly property string aiGlyph: "󰚩"      // md-robot
  readonly property string refreshGlyph: "󰑐" // md-refresh
  readonly property string alertGlyph: "󰗖"   // md-alert_circle_outline

  // ── Helpers ────────────────────────────────────────────────────

  // The kit's own idiom is binary, not a traffic-light gradient: a meter
  // stays in bar.foreground until it actually needs attention, then it's
  // bar.urgent (see the battery meter and network's packet-loss color).
  function severityColor(sev) {
    return (sev === "high" || sev === "critical") ? root.bar.urgent : root.bar.foreground
  }

  function formatCountdown(resetAt) {
    if (!resetAt) return ""
    var diff = Math.max(0, (new Date(resetAt).getTime() - Date.now()) / 1000)
    if (diff <= 0) return "now"
    if (diff >= 86400) return Math.floor(diff / 86400) + "d " + Math.floor((diff % 86400) / 3600) + "h"
    var h = Math.floor(diff / 3600), m = Math.floor((diff % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }

  function severityRank(s) {
    switch (s) {
      case "critical": return 3; case "high": return 2
      case "mid": return 1; case "low": return 0; default: return -1
    }
  }

  function pickBusiest() {
    var candidates = entries.filter(function(e) { return e.status !== "error" })
    if (candidates.length === 0) return null
    if (vendorSetting !== "auto") {
      for (var i = 0; i < candidates.length; i++)
        if (candidates[i].id === vendorSetting) return candidates[i]
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
    // A provider that dropped out of the last payload (renamed/removed
    // from config) shouldn't leave the detail tab stuck on a dead id.
    if (activeTabId !== "" && !entries.some(function(e) { return e.id === activeTabId }))
      activeTabId = ""
  }

  // ── Refresh ────────────────────────────────────────────────────
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

  // ── Bar content ────────────────────────────────────────────────
  readonly property var primaryMetric: primaryEntry && primaryEntry.metrics && primaryEntry.metrics[0] ? primaryEntry.metrics[0] : null
  readonly property string barPercentText: primaryMetric ? primaryMetric.percent + "%" : "—"
  readonly property string barCountdownText: showCountdown && primaryMetric ? formatCountdown(primaryMetric.reset_at) : ""
  readonly property color barGlyphColor: primaryMetric ? severityColor(primaryMetric.severity) : root.bar.barForeground
  readonly property string tooltipText: {
    if (!primaryEntry) return "AI Usage — right-click to refresh"
    var t = (primaryEntry.display_name || primaryEntry.id) + " — " + barPercentText
    if (primaryEntry.plan) t += " · " + primaryEntry.plan
    if (barCountdownText) t += " · resets in " + barCountdownText
    return t + " · right-click to refresh"
  }

  implicitWidth: root.vertical ? root.barSize : barRow.implicitWidth + Style.space(14)
  implicitHeight: root.vertical ? barColumn.implicitHeight + Style.space(10) : root.barSize

  Row {
    id: barRow
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: Style.space(5)

    OpticalGlyph {
      visible: root.showIcon
      anchors.verticalCenter: parent.verticalCenter
      text: root.aiGlyph
      color: root.barGlyphColor
      fontFamily: root.bar.fontFamily
      fontSize: Style.font.body
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.barPercentText + (root.barCountdownText ? "  " + root.barCountdownText : "")
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body

      Behavior on color {
        enabled: !root.bar || root.bar.foregroundAnimationEnabled
        ColorAnimation { duration: 160 }
      }
    }
  }

  Column {
    id: barColumn
    visible: root.vertical
    anchors.centerIn: parent
    spacing: Style.space(2)

    OpticalGlyph {
      visible: root.showIcon
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.aiGlyph
      color: root.barGlyphColor
      fontFamily: root.bar.fontFamily
      fontSize: Style.font.body
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.barPercentText
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.refresh()
      else root.toggle()
    }
    onEntered: root.bar.showTooltip(root, root.tooltipText)
    onExited: root.bar.hideTooltip(root)
  }

  // ── Popup panel ────────────────────────────────────────────────
  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(panelContent.implicitHeight, Style.space(520))

    Column {
      id: panelContent
      width: parent.width
      spacing: Style.spacing.md

      PanelHero {
        width: parent.width
        foreground: root.bar.foreground
        title: "AI Usage"
        meta: root.stale ? "showing stale data" : ""

        iconComponent: Component {
          BorderSurface {
            width: Style.space(32)
            height: Style.space(32)
            radius: Style.spacing.labelGap
            color: Style.normalFillFor(root.bar.foreground, Color.accent)
            borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

            Text {
              anchors.centerIn: parent
              text: root.aiGlyph
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.iconLarge
            }
          }
        }

        trailingControl: Component {
          Button {
            iconText: root.refreshGlyph
            tooltipText: proc.running ? "Refreshing…" : "Refresh"
            foreground: root.bar.foreground
            horizontalPadding: Style.spacing.sm
            verticalPadding: Style.spacing.sm
            iconSpinning: proc.running
            enabled: !proc.running
            opacity: enabled ? 1.0 : 0.55
            onClicked: root.refresh()
          }
        }
      }

      PanelSeparator { foreground: root.bar.foreground }

      ButtonGroup {
        id: tabs
        width: parent.width
        value: root.activeTabId
        foreground: root.bar.foreground
        background: "transparent"
        accent: Color.accent
        fontSize: Style.font.bodySmall
        options: [{ value: "", label: "Overview", icon: root.aiGlyph }].concat(
          root.entries.filter(function(e) { return e.status !== "error" }).map(function(e) {
            return { value: e.id, label: e.short_name || e.id, icon: root.aiGlyph, tooltip: e.display_name || e.id }
          })
        )
        onChanged: function(v) { root.activeTabId = v }
      }

      // ── Overview ─────────────────────────────────────────────
      Column {
        visible: root.activeTabId === ""
        width: parent.width
        spacing: Style.spacing.xs

        Repeater {
          model: root.entries

          delegate: BorderSurface {
            id: providerRow
            required property var modelData
            readonly property var metric: modelData.metrics && modelData.metrics[0] ? modelData.metrics[0] : null
            readonly property bool isError: modelData.status === "error"

            width: parent.width
            height: rowInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: rowMouse.containsMouse && !isError ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent"

            Column {
              id: rowInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(6)
              spacing: Style.spacing.xxs

              Row {
                width: parent.width
                spacing: Style.space(8)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: providerRow.isError ? root.alertGlyph : root.aiGlyph
                  color: providerRow.isError ? root.bar.urgent : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  width: Style.space(18)
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.display_name || modelData.id
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                  width: parent.width - Style.space(18) - Style.space(8) - trailer.implicitWidth - Style.space(8)
                }

                Row {
                  id: trailer
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(8)

                  Text {
                    visible: !providerRow.isError
                    text: providerRow.metric ? providerRow.metric.percent + "%" : "—"
                    color: providerRow.metric ? root.severityColor(providerRow.metric.severity) : root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    visible: !providerRow.isError && providerRow.metric && !!providerRow.metric.reset_at
                    text: providerRow.metric ? root.formatCountdown(providerRow.metric.reset_at) : ""
                    color: Qt.darker(root.bar.foreground, 1.3)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }

                  Text {
                    visible: providerRow.isError
                    text: "error"
                    color: root.bar.urgent
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }
                }
              }

              Text {
                visible: !providerRow.isError && !!modelData.plan
                text: modelData.plan || ""
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                leftPadding: Style.space(26)
              }

              Text {
                visible: providerRow.isError && !!modelData.error
                text: modelData.error || ""
                color: root.bar.urgent
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                leftPadding: Style.space(26)
                width: parent.width - Style.space(26)
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
              }
            }

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: !providerRow.isError
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeTabId = modelData.id
            }
          }
        }

        Text {
          visible: root.entries.length === 0
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: "No providers configured.\n\nRun ai-usagebar to set up providers in\n~/.config/ai-usagebar/config.toml"
          color: Qt.darker(root.bar.foreground, 1.3)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }

      // ── Per-provider detail ──────────────────────────────────
      Column {
        visible: root.activeTabId !== ""
        width: parent.width
        spacing: Style.spacing.md

        Repeater {
          model: root.entries.filter(function(e) { return e.status !== "error" })

          delegate: Column {
            required property var modelData
            visible: modelData.id === root.activeTabId
            width: parent.width
            spacing: Style.spacing.sm

            PanelHero {
              width: parent.width
              foreground: root.bar.foreground
              title: modelData.display_name || modelData.id
              meta: modelData.plan || ""
              detail: modelData.status === "ready" ? "active" : modelData.status

              iconComponent: Component {
                BorderSurface {
                  width: Style.space(28)
                  height: Style.space(28)
                  radius: Style.spacing.labelGap
                  color: Style.normalFillFor(root.bar.foreground, Color.accent)
                  borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

                  Text {
                    anchors.centerIn: parent
                    text: root.aiGlyph
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }
              }
            }

            PanelSeparator { foreground: root.bar.foreground }

            Repeater {
              model: modelData.metrics || []

              delegate: Column {
                required property var modelData
                width: parent.width
                spacing: Style.spacing.xxs

                Row {
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    text: modelData.label || "Usage"
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    width: parent.width - Style.space(110)
                    elide: Text.ElideRight
                  }

                  Text {
                    text: modelData.percent + "%"
                    color: root.severityColor(modelData.severity)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    text: root.formatCountdown(modelData.reset_at)
                    color: Qt.darker(root.bar.foreground, 1.3)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                BorderSurface {
                  width: parent.width
                  height: Style.space(4)
                  radius: Style.space(2)
                  color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)

                  Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * modelData.percent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.severityColor(modelData.severity)

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                  }
                }

                Text {
                  visible: !!modelData.detail && modelData.detail.length > 0
                  text: modelData.detail || ""
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  width: parent.width
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }
      }
    }
  }
}

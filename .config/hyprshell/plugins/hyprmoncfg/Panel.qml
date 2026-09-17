import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

// hyprmoncfg editor.
//
// A spatial view of the current arrangement — drag a display, it snaps to its
// neighbours — plus the per-display settings that a profile records. All state
// worth keeping lives in Service.qml; this holds only the working copy being
// edited, which is discarded on close unless it was saved or applied.
Item {
  id: root

  // Injected by the shell's panel loader.
  property var shell: null
  property var manifest: null
  property var service: null

  property bool opened: false

  // Working copy of the arrangement. `revision` is the change ticket: the
  // entries are mutated in place (a dragged display must not rebuild its
  // delegate mid-drag), so bindings depend on the counter instead of the array.
  property var entries: []
  property int revision: 0
  property int selectedIndex: 0
  property string profileName: ""
  property string lidCondition: "any"
  property bool dirty: false
  property string notice: ""

  // Snap guides, in layout coordinates. null = no guide on that axis.
  property var guideX: null
  property var guideY: null

  // Guides only explain the snap that just happened on release; they fade
  // shortly after so the canvas is clean for the next drag.
  property Timer guideFade: Timer {
    interval: 600
    onTriggered: {
      root.guideX = null
      root.guideY = null
    }
  }

  readonly property var selected: (root.revision, root.entries[root.selectedIndex] || null)
  readonly property var clashes: (root.revision, Model.overlaps(root.entries))

  function touch() {
    revision++
    dirty = true
  }

  // Every edit replaces the entry with a fresh object instead of mutating it
  // in place. The canvas delegate and the inspector bind to the entry object
  // itself; an in-place write leaves the reference unchanged, so those
  // bindings would keep rendering the pre-edit position or setting until the
  // panel was closed and reopened. With a fresh object, the revision bump in
  // touch() re-runs every reader and the edit lands on screen immediately.
  function updateEntry(index, patch) {
    if (index < 0 || index >= entries.length) return
    var next = JSON.parse(JSON.stringify(entries[index]))
    for (var key in patch) next[key] = patch[key]
    entries[index] = next
    touch()
  }

  // ------------------------------------------------------------- lifecycle

  function open(payload) {
    if (service) service.refresh()
    reload()
    opened = true
  }

  function close() {
    opened = false
    notice = ""
  }

  function dismiss() {
    if (shell && typeof shell.hide === "function") shell.hide((manifest && manifest.id) || "hyprmoncfg")
    else close()
  }

  // Start from what is on screen right now, so the editor always opens
  // showing the truth rather than the last thing that was saved.
  //
  // Deliberately does not ask the service to re-probe: a probe reassigns
  // `monitors`, which wakes the Connections at the bottom of this file, which
  // lands back here. open() does the one refresh that is wanted.
  function reload() {
    if (!service) return
    entries = Model.entriesFromMonitors(service.monitors)
    revision++
    selectedIndex = 0
    profileName = service.activeProfile || suggestName()
    lidCondition = "any"
    dirty = false
    guideX = null
    guideY = null
    readBrightness()
  }

  function loadProfile(name) {
    if (!service) return
    var profile = service.profileByName(name)
    if (!profile) return
    entries = Model.resolveProfile(profile, service.monitors)
    revision++
    selectedIndex = 0
    profileName = profile.name
    lidCondition = String(profile.lid || "any")
    dirty = false
    notice = "Loaded " + profile.name
    readBrightness()
  }

  // A profile with no name yet is named after the displays it describes, which
  // is what the user would have typed anyway.
  function suggestName() {
    if (!service) return "default"
    var count = (service.monitors || []).filter(function(m) { return m.disabled !== true }).length
    if (count <= 1) return "laptop"
    return count === 2 ? "docked" : count + " displays"
  }

  function apply() {
    if (!service) return
    if (clashes.length > 0) {
      notice = "Displays overlap: " + clashes[0]
      return
    }
    Model.normalizeOrigin(entries)
    revision++
    // Applying under a name that already owns a profile has to refresh that
    // profile too: the service records it as active, and the next auto-switch
    // would re-apply the stale file and quietly revert what was just applied
    // to the screens.
    var synced = false
    if (profileName && service.profileByName(profileName)) {
      var saveError = service.saveProfile(profileName, entries, lidCondition)
      if (saveError) {
        notice = saveError
        return
      }
      synced = true
      dirty = false
    }
    var error = service.applyEntries(entries, profileName || "unsaved")
    notice = error ? error : (synced ? "Saved and applied" : "Applied")
  }

  function save() {
    if (!service) return
    var name = String(profileName || "").trim()
    if (!name) {
      notice = "Give the profile a name first"
      return
    }
    Model.normalizeOrigin(entries)
    revision++
    var error = service.saveProfile(name, entries, lidCondition)
    if (error) {
      notice = error
      return
    }
    dirty = false
    notice = "Saved " + name
  }

  function removeCurrent() {
    if (!service) return
    var error = service.removeProfile(profileName)
    notice = error ? error : "Deleted " + profileName
  }

  // ------------------------------------------------------------ brightness
  //
  // Live hardware state, not profile state, ported from upstream's panel: a
  // display either answers the brightness helper or it does not, and the
  // second case is shown as "unavailable" rather than hidden, so two screens
  // with different controls never read as one broken settings page.

  property int brightnessPercent: 1
  property bool brightnessAvailable: false
  property bool brightnessLoading: false
  property bool brightnessReadQueued: false
  property bool brightnessSetQueued: false
  property int brightnessSetQueuedPercent: 1
  property string brightnessProbeOutput: ""

  readonly property string binDir: Quickshell.env("HOME") + "/.local/share/hyprshell/bin"

  function readBrightness() {
    if (!selected || !selected.output || selected.enabled === false) {
      brightnessLoading = false
      brightnessAvailable = false
      return
    }
    // A probe already in flight was started before this selection; let it
    // land, then ask again for the display now in the inspector.
    if (brightnessProbe.running) {
      brightnessReadQueued = true
      return
    }
    brightnessReadQueued = false
    brightnessProbeOutput = selected.output
    if (!brightnessAvailable) brightnessLoading = true
    brightnessProbe.command = [binDir + "/brightness-display", "--monitor", selected.output]
    brightnessProbe.running = true
  }

  function startBrightnessSet(percent) {
    brightnessSetter.command = [binDir + "/brightness-display", "--no-osd",
      "--monitor", selected.output, percent + "%"]
    brightnessSetter.running = true
  }

  function setBrightness(percent) {
    if (!selected || !selected.output || !brightnessAvailable) return
    var value = Model.clampBrightness(percent)
    brightnessPercent = value
    // Writes are serialized: a set already running takes the latest value
    // with it when it exits, so a fast slider never drops its final position.
    if (brightnessSetter.running) {
      brightnessSetQueued = true
      brightnessSetQueuedPercent = value
      return
    }
    startBrightnessSet(value)
  }

  Process {
    id: brightnessProbe
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = parseInt(String(text).trim(), 10)
        // A reading for a display that is no longer selected says nothing
        // about the one that is.
        if (root.brightnessProbeOutput === (root.selected ? root.selected.output : "")) {
          root.brightnessAvailable = isFinite(value) && value > 0
          if (root.brightnessAvailable) root.brightnessPercent = value
          root.brightnessLoading = false
        }
        if (root.brightnessReadQueued) root.readBrightness()
      }
    }
  }

  Process {
    id: brightnessSetter
    onExited: {
      if (!root.brightnessSetQueued) return
      root.brightnessSetQueued = false
      if (root.selected && root.selected.output) root.startBrightnessSet(root.brightnessSetQueuedPercent)
    }
  }

  // The slider previews continuously; the hardware write follows at a human
  // pace rather than once per pixel of movement.
  property Timer brightnessDebounce: Timer {
    interval: 150
    onTriggered: root.setBrightness(root.brightnessPercent)
  }

  onSelectedIndexChanged: readBrightness()

  // ---------------------------------------------------------------- window

  PanelWindow {
    id: window

    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "hyprshell-hyprmoncfg"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    Item {
      id: card

      anchors.centerIn: parent
      width: Math.min(parent.width - Style.space(80), Style.space(1120))
      height: Math.min(parent.height - Style.space(80), Style.space(760))

      // Swallow clicks so the scrim below does not dismiss the editor.
      MouseArea { anchors.fill: parent; onClicked: {} }

      Rectangle {
        anchors.fill: parent
        color: Color.popups.background
        radius: Style.cornerRadius
        border.width: Style.normalBorderWidth
        border.color: Color.popups.border
      }

      focus: true
      Keys.onPressed: function(event) {
        if (event.key !== Qt.Key_Escape) return
        event.accepted = true
        root.dismiss()
      }

      Item {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding

        // ---------------------------------------------------------- header

        Item {
          id: header
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: title.height + subtitle.height + Style.spacing.xs

          Text {
            id: title
            text: "Displays"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Text {
            id: subtitle
            anchors.top: title.bottom
            anchors.topMargin: Style.spacing.xs
            text: {
              var parts = [root.service ? root.service.setupLabel : ""]
              if (root.service && root.service.lidClosed) parts.push("lid closed")
              if (root.service && root.service.activeProfile) parts.push("active: " + root.service.activeProfile)
              return parts.filter(function(p) { return p }).join("  ·  ")
            }
            color: Qt.darker(Color.popups.text, 1.5)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.controlGap

            Button {
              text: root.service && root.service.autoSwitch ? "Auto-switch on" : "Auto-switch off"
              bordered: true
              selected: root.service && root.service.autoSwitch
              tooltipText: "Apply the matching profile automatically on hotplug and lid events"
              onClicked: if (root.service) root.service.setAutoSwitch(!root.service.autoSwitch)
            }

            Button {
              text: "Close"
              bordered: true
              onClicked: root.dismiss()
            }
          }
        }

        PanelSeparator {
          id: headerRule
          anchors.top: header.bottom
          anchors.topMargin: Style.spacing.lg
          foreground: Color.popups.text
        }

        // ---------------------------------------------------------- canvas

        Item {
          id: canvas

          anchors.top: headerRule.bottom
          anchors.topMargin: Style.spacing.panelGap
          anchors.left: parent.left
          anchors.right: inspector.left
          anchors.rightMargin: Style.spacing.panelGap
          anchors.bottom: footer.top
          anchors.bottomMargin: Style.spacing.panelGap
          clip: true

          // The fit is derived from the model only. A drag never touches the
          // entries — the dragged card rides its own pixel offset and the
          // position commits once, on release — so this box cannot move while
          // the pointer is down, which is what keeps the other displays still.
          readonly property var box: (root.revision, Model.bounds(root.entries))
          readonly property real spanX: Math.max(1, box.right - box.left)
          readonly property real spanY: Math.max(1, box.bottom - box.top)
          readonly property real fitScale: Math.min(width / spanX, height / spanY) * 0.82
          readonly property real originX: (width - spanX * fitScale) / 2 - box.left * fitScale
          readonly property real originY: (height - spanY * fitScale) / 2 - box.top * fitScale

          function toCanvasX(layoutX) { return originX + layoutX * fitScale }
          function toCanvasY(layoutY) { return originY + layoutY * fitScale }

          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.03)
            radius: Style.cornerRadius
          }

          // Snap guides
          Rectangle {
            visible: root.guideX !== null
            width: 1
            color: Color.accent
            opacity: 0.7
            x: root.guideX === null ? 0 : canvas.toCanvasX(root.guideX)
            y: 0
            height: canvas.height
          }

          Rectangle {
            visible: root.guideY !== null
            height: 1
            color: Color.accent
            opacity: 0.7
            y: root.guideY === null ? 0 : canvas.toCanvasY(root.guideY)
            x: 0
            width: canvas.width
          }

          Repeater {
            model: root.entries.length

            delegate: Rectangle {
              id: screenRect

              required property int index
              readonly property var entry: (root.revision, root.entries[index])
              readonly property var logical: (root.revision, entry ? Model.logicalSize(entry) : { width: 0, height: 0 })
              readonly property var layoutPos: (root.revision, entry ? Model.parsePosition(entry.position) : { x: 0, y: 0 })
              readonly property bool isSelected: index === root.selectedIndex
              readonly property bool off: !entry || entry.enabled === false
              // The in-flight drag, in canvas pixels. Nothing but these two
              // values changes while the pointer is down, so the card is the
              // only thing that moves.
              property real dragOffsetX: 0
              property real dragOffsetY: 0

              visible: !off || isSelected
              x: canvas.toCanvasX(layoutPos.x) + dragOffsetX
              y: canvas.toCanvasY(layoutPos.y) + dragOffsetY
              width: Math.max(2, logical.width * canvas.fitScale)
              height: Math.max(2, logical.height * canvas.fitScale)
              opacity: off ? 0.35 : 1

              color: isSelected
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                : Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.08)
              border.width: isSelected ? Math.max(2, Style.normalBorderWidth * 2) : Style.normalBorderWidth
              border.color: isSelected ? Color.accent : Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.4)
              radius: Style.cornerRadius

              Column {
                anchors.centerIn: parent
                spacing: Style.spacing.xxs
                width: parent.width - Style.spacing.lg

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  elide: Text.ElideRight
                  text: screenRect.entry ? screenRect.entry.output : ""
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  elide: Text.ElideRight
                  visible: parent.width > Style.space(90)
                  text: screenRect.entry ? screenRect.entry.label : ""
                  color: Qt.darker(Color.popups.text, 1.6)
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  elide: Text.ElideRight
                  visible: parent.width > Style.space(90)
                  text: screenRect.off ? "off"
                    : Model.modeLabel(screenRect.entry.mode) + "   " + Math.round((Number(screenRect.entry.scale) || 1) * 100) + "%"
                  color: Qt.darker(Color.popups.text, 1.6)
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }

              MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: screenRect.off ? Qt.PointingHandCursor
                  : (dragStarted ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                hoverEnabled: true
                // Pointer coordinates must come from the stationary canvas:
                // mouse.x/y are card-local, and the card moves with the drag.
                property real pointerStartX: 0
                property real pointerStartY: 0
                property bool dragStarted: false

                onPressed: function(mouse) {
                  root.selectedIndex = screenRect.index
                  var point = mapToItem(canvas, mouse.x, mouse.y)
                  pointerStartX = point.x
                  pointerStartY = point.y
                  dragStarted = false
                  screenRect.dragOffsetX = 0
                  screenRect.dragOffsetY = 0
                }

                onPositionChanged: function(mouse) {
                  if (!pressed || screenRect.off) return
                  var point = mapToItem(canvas, mouse.x, mouse.y)
                  var deltaX = point.x - pointerStartX
                  var deltaY = point.y - pointerStartY
                  // A small dead zone so a click-to-select never reads as a
                  // drag and drops the display a pixel or two away.
                  if (!dragStarted) {
                    var threshold = Style.space(6)
                    if (deltaX * deltaX + deltaY * deltaY < threshold * threshold) return
                    dragStarted = true
                  }
                  screenRect.dragOffsetX = deltaX
                  screenRect.dragOffsetY = deltaY
                }

                onReleased: {
                  if (!dragStarted) {
                    screenRect.dragOffsetX = 0
                    screenRect.dragOffsetY = 0
                    return
                  }
                  // One commit per drag: translate the pixel offset back into
                  // layout coordinates, snap it against the neighbours, and
                  // only then touch the model. The view refits afterwards,
                  // with every display already in its final place.
                  var nextX = screenRect.layoutPos.x + screenRect.dragOffsetX / canvas.fitScale
                  var nextY = screenRect.layoutPos.y + screenRect.dragOffsetY / canvas.fitScale
                  var snapDistance = Math.max(1, Math.round(Style.space(12) / canvas.fitScale))
                  screenRect.dragOffsetX = 0
                  screenRect.dragOffsetY = 0
                  dragStarted = false
                  var snapped = Model.snapPosition(root.entries, screenRect.index, nextX, nextY, snapDistance)
                  root.updateEntry(screenRect.index, { position: Model.formatPosition(snapped.x, snapped.y) })
                  root.guideX = snapped.guideX
                  root.guideY = snapped.guideY
                  root.guideFade.restart()
                }

                onCanceled: {
                  dragStarted = false
                  screenRect.dragOffsetX = 0
                  screenRect.dragOffsetY = 0
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.spacing.md
            text: root.clashes.length > 0 ? "Overlapping: " + root.clashes.join(", ")
              : "Drag a display to rearrange — it snaps to its neighbours"
            color: root.clashes.length > 0 ? Color.urgent : Qt.darker(Color.popups.text, 1.7)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        // ------------------------------------------------------- inspector

        Flickable {
          id: inspector

          anchors.top: headerRule.bottom
          anchors.topMargin: Style.spacing.panelGap
          anchors.right: parent.right
          anchors.bottom: footer.top
          anchors.bottomMargin: Style.spacing.panelGap
          width: Style.space(300)
          clip: true
          contentHeight: settings.height
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: settings
            width: inspector.width
            spacing: Style.spacing.rowGap

            PanelSectionHeader {
              text: root.selected ? root.selected.label.toUpperCase() : "NO DISPLAY"
              foreground: Color.popups.text
              width: parent.width
              elide: Text.ElideRight
            }

            Text {
              visible: !!root.selected
              text: root.selected ? root.selected.output + "  ·  " + String(root.selected.key || "").split("|").pop() : ""
              color: Qt.darker(Color.popups.text, 1.7)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              width: parent.width
              elide: Text.ElideRight
            }

            Toggle {
              width: parent.width
              visible: !!root.selected
              label: "Enabled"
              description: "Off leaves the output dark"
              checked: root.selected ? root.selected.enabled !== false : false
              foreground: Color.popups.text
              onClicked: {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { enabled: root.selected.enabled === false })
              }
            }

            Dropdown {
              width: parent.width
              visible: !!root.selected
              label: "Resolution"
              foreground: Color.popups.text
              value: root.selected ? String(root.selected.mode) : ""
              options: root.selected && root.selected.availableModes
                ? root.selected.availableModes.map(function(mode) {
                    return { value: mode, label: Model.modeLabel(mode) }
                  })
                : []
              onChanged: function(next) {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { mode: next })
              }
            }

            Dropdown {
              width: parent.width
              visible: !!root.selected
              label: "Scale"
              foreground: Color.popups.text
              value: root.selected ? Model.normalizeScale(root.selected.scale) : ""
              options: root.selected
                ? Model.availableScales(root.selected).map(function(scale) {
                    return { value: scale, label: Model.scaleLabel(scale) }
                  })
                : []
              onChanged: function(next) {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { scale: Number(next) })
              }
            }

            Column {
              width: parent.width
              spacing: Style.spacing.labelGap
              visible: !!root.selected

              Text {
                text: "Rotation"
                color: Qt.darker(Color.popups.text, 1.4)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              ButtonGroup {
                foreground: Color.popups.text
                background: Color.popups.background
                value: root.selected ? String(Number(root.selected.transform) || 0) : "0"
                options: [
                  { value: "0", label: "0°" },
                  { value: "1", label: "90°" },
                  { value: "2", label: "180°" },
                  { value: "3", label: "270°" }
                ]
                onChanged: function(next) {
                  if (!root.selected) return
                  root.updateEntry(root.selectedIndex, { transform: parseInt(next, 10) })
                }
              }
            }

            Dropdown {
              width: parent.width
              visible: !!root.selected && root.entries.length > 1
              label: "Mirror of"
              foreground: Color.popups.text
              value: root.selected ? String(root.selected.mirror || "") : ""
              options: {
                var out = [{ value: "", label: "Not mirrored" }]
                for (var i = 0; i < root.entries.length; i++) {
                  if (i === root.selectedIndex) continue
                  out.push({ value: root.entries[i].output, label: root.entries[i].output + " — " + root.entries[i].label })
                }
                return out
              }
              onChanged: function(next) {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { mirror: next })
              }
            }

            Dropdown {
              width: parent.width
              visible: !!root.selected
              label: "Color"
              foreground: Color.popups.text
              value: root.selected ? String(root.selected.cm || "auto") : "auto"
              options: Model.COLOR_PRESETS
              onChanged: function(next) {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { cm: next })
              }
            }

            Toggle {
              width: parent.width
              visible: !!root.selected
              label: "Variable refresh"
              description: "VRR / adaptive sync"
              checked: root.selected ? root.selected.vrr === true : false
              foreground: Color.popups.text
              onClicked: {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { vrr: root.selected.vrr !== true })
              }
            }

            Column {
              width: parent.width
              spacing: Style.spacing.labelGap
              visible: !!root.selected

              Item {
                width: parent.width
                height: Math.max(brightnessTitle.implicitHeight, brightnessValue.implicitHeight)

                PanelSectionHeader {
                  id: brightnessTitle
                  anchors.left: parent.left
                  anchors.right: brightnessValue.left
                  anchors.rightMargin: Style.spacing.xs
                  anchors.verticalCenter: parent.verticalCenter
                  text: "BRIGHTNESS · " + (root.selected ? root.selected.output : "")
                  elide: Text.ElideRight
                  foreground: Color.popups.text
                }

                Text {
                  id: brightnessValue
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.brightnessLoading ? "…"
                    : (root.brightnessAvailable ? root.brightnessPercent + "%" : "Unavailable")
                  color: Qt.darker(Color.popups.text, 1.6)
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              PanelSlider {
                width: parent.width
                visible: root.brightnessAvailable
                opacity: root.brightnessLoading ? 0.6 : 1
                minimum: 1
                maximum: 100
                integer: true
                value: root.brightnessPercent
                onMoved: function(next) {
                  root.brightnessPercent = Model.clampBrightness(next)
                  root.brightnessDebounce.restart()
                }
                onReleased: function(next) {
                  root.brightnessDebounce.stop()
                  root.setBrightness(next)
                }
              }

              Text {
                width: parent.width
                visible: !root.brightnessAvailable
                text: root.brightnessLoading ? "Reading display…"
                  : "This display has no brightness control the shell can reach"
                color: Qt.darker(Color.popups.text, 1.7)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
              }
            }

            PanelSeparator { foreground: Color.popups.text }

            PanelSectionHeader {
              text: "WORKSPACES"
              foreground: Color.popups.text
            }

            Text {
              text: "Which workspaces live on this display. Ranges work: 1-5"
              color: Qt.darker(Color.popups.text, 1.7)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              width: parent.width
              wrapMode: Text.WordWrap
            }

            TextField {
              width: parent.width
              visible: !!root.selected
              placeholderText: "1-5"
              foreground: Color.popups.text
              text: root.selected ? Model.formatWorkspaces(root.selected.workspaces) : ""
              onEditingFinished: {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { workspaces: Model.parseWorkspaces(text) })
              }
            }

            TextField {
              width: parent.width
              visible: !!root.selected && (root.selected.workspaces || []).length > 0
              placeholderText: "Default workspace"
              foreground: Color.popups.text
              text: root.selected ? String(root.selected.defaultWorkspace || "") : ""
              onEditingFinished: {
                if (!root.selected) return
                root.updateEntry(root.selectedIndex, { defaultWorkspace: text.trim() })
              }
            }
          }
        }

        // ---------------------------------------------------------- footer

        Item {
          id: footer
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: footerRow.height + footerRule.height + Style.spacing.lg * 2

          PanelSeparator {
            id: footerRule
            anchors.top: parent.top
            foreground: Color.popups.text
          }

          Row {
            id: footerRow
            anchors.top: footerRule.bottom
            anchors.topMargin: Style.spacing.lg
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Style.spacing.controlGap

            Dropdown {
              width: Style.space(190)
              anchors.verticalCenter: parent.verticalCenter
              label: ""
              showLabel: false
              foreground: Color.popups.text
              value: root.profileName
              options: {
                var list = root.service ? root.service.profiles : []
                if (list.length === 0) return [{ value: "", label: "No saved profiles" }]
                return list.map(function(profile) {
                  var lid = String(profile.lid || "any")
                  return {
                    value: profile.name,
                    label: profile.name + (lid === "any" ? "" : "  (lid " + lid + ")")
                  }
                })
              }
              onChanged: function(next) { if (next) root.loadProfile(next) }
            }

            TextField {
              width: Style.space(180)
              anchors.verticalCenter: parent.verticalCenter
              placeholderText: "Profile name"
              foreground: Color.popups.text
              text: root.profileName
              onTextEdited: root.profileName = text
            }

            Dropdown {
              width: Style.space(150)
              anchors.verticalCenter: parent.verticalCenter
              label: ""
              showLabel: false
              foreground: Color.popups.text
              value: root.lidCondition
              options: [
                { value: "any", label: "Lid: any" },
                { value: "open", label: "Lid: open" },
                { value: "closed", label: "Lid: closed" }
              ]
              onChanged: function(next) { root.lidCondition = next; root.dirty = true }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.notice
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Row {
            anchors.top: footerRule.bottom
            anchors.topMargin: Style.spacing.lg
            anchors.right: parent.right
            spacing: Style.spacing.controlGap

            Button {
              text: "Revert"
              bordered: true
              onClicked: root.reload()
            }

            Button {
              text: "Delete"
              bordered: true
              foreground: Color.urgent
              visible: root.service ? (root.service.profiles, root.service.profileByName(root.profileName) !== null) : false
              onClicked: root.removeCurrent()
            }

            Button {
              text: "Save"
              bordered: true
              selected: root.dirty
              onClicked: root.save()
            }

            Button {
              text: "Apply"
              bordered: true
              selected: true
              onClicked: root.apply()
            }
          }
        }
      }
    }

    Connections {
      target: root.service
      enabled: root.opened

      // A display coming or going while the editor is open would leave it
      // drawing a machine that no longer exists.
      function onMonitorsChanged() {
        if (root.dirty) return
        root.reload()
      }
    }
  }
}

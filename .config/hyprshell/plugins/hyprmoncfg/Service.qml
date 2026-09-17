import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Model.js" as Model

// hyprmoncfg daemon.
//
// Owns everything stateful: the live monitor list, the saved profiles, the lid
// switch, and the decision of which profile the current set of displays wants.
// The editor panel is a view onto this object and holds no state of its own,
// so a layout applied from the CLI and one applied from the UI travel the same
// path.
//
// Runs inside the shell rather than as a separate systemd unit: the shell is
// already a long-lived process with a Hyprland event socket open, and a second
// daemon would only duplicate that plumbing (and race it on hotplug).
QtObject {
  id: root

  // Injected by the shell's service loader.
  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string configDir: home + "/.config/hyprmoncfg"
  readonly property string profilesDir: configDir + "/profiles"
  readonly property string currentLuaPath: configDir + "/current.lua"
  readonly property string statePath: configDir + "/state.json"
  readonly property string configPath: configDir + "/config.json"
  readonly property string binDir: home + "/.local/share/hyprshell/bin"

  // ---------------------------------------------------------------- state

  // Live `hyprctl -j monitors all`, disabled outputs included.
  property var monitors: []
  // Every saved profile, newest write last.
  property var profiles: []
  property bool lidClosed: false
  property bool autoSwitch: true
  property bool notify: true
  property string activeProfile: ""
  property string lastError: ""
  property bool applying: false
  property bool loaded: false

  readonly property string setupLabel: Model.setupLabel(monitors)
  readonly property string setupKey: Model.setupKey(monitors)

  // `monitors` and `profiles` already emit their own change signals; the
  // panel listens on those. Only the apply outcome needs one of its own.
  signal profilesReloaded()
  signal applied(string name)

  function profileByName(name) {
    var wanted = String(name || "").trim().toLowerCase()
    for (var i = 0; i < profiles.length; i++) {
      if (String(profiles[i].name || "").trim().toLowerCase() === wanted) return profiles[i]
    }
    return null
  }

  function matchingProfile() {
    return Model.bestProfile(profiles, monitors, lidClosed)
  }

  // ---------------------------------------------------------------- reading

  function refresh() {
    if (!monitorProbe.running) monitorProbe.running = true
  }

  function reloadProfiles() {
    if (!profileReader.running) profileReader.running = true
  }

  property Process monitorProbe: Process {
    command: ["hyprctl", "-j", "monitors", "all"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          if (Array.isArray(parsed)) {
            root.monitors = parsed
          }
        } catch (e) {
          console.warn("hyprmoncfg: could not parse hyprctl monitors:", e)
        }
      }
    }
  }

  // One jq slurp over the profile directory. An empty (or missing) directory
  // answers with [] rather than a jq usage error.
  property Process profileReader: Process {
    command: ["bash", "-c",
      "shopt -s nullglob; dir=\"$1\"; mkdir -p \"$dir\"; set -- \"$dir\"/*.json; "
      + "if (( $# == 0 )); then echo '[]'; else jq -s '.' \"$@\" 2>/dev/null || echo '[]'; fi",
      "hyprmoncfg", root.profilesDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.profiles = Array.isArray(parsed) ? parsed : []
        } catch (e) {
          console.warn("hyprmoncfg: could not parse profiles:", e)
          root.profiles = []
        }
        root.profilesReloaded()
        if (!root.loaded) {
          root.loaded = true
          // Nothing has switched displays yet, so the first pass only records
          // what is already on screen — see autoApply's sameAsLive guard.
          root.autoApply("startup")
        }
      }
    }
  }

  // Settings and last-applied state are two files but one answer; jq folds
  // them into a single object so a missing or half-written file just
  // contributes nothing instead of derailing the parse.
  property Process settingsReader: Process {
    command: ["bash", "-c",
      "{ [[ -f $1 ]] && cat \"$1\" || echo '{}'; [[ -f $2 ]] && cat \"$2\" || echo '{}'; } "
      + "| jq -s 'add // {}' 2>/dev/null || echo '{}'",
      "hyprmoncfg", root.configPath, root.statePath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(String(text || "{}"))
          if (parsed.autoSwitch !== undefined) root.autoSwitch = parsed.autoSwitch !== false
          if (parsed.notify !== undefined) root.notify = parsed.notify !== false
          if (parsed.active !== undefined) root.activeProfile = String(parsed.active || "")
        } catch (e) {
          console.warn("hyprmoncfg: could not read settings:", e)
        }
        root.reloadProfiles()
      }
    }
  }

  // ---------------------------------------------------------------- writing

  // Every write goes through one of these: the text rides in argv, never
  // through a shell, so a profile name with a quote in it cannot become code.
  function writeFile(process, path, content, thenRun) {
    process.pendingNext = thenRun || null
    process.command = ["bash", "-c",
      "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"",
      "hyprmoncfg", content, path]
    process.running = true
  }

  property Process luaWriter: Process {
    property var pendingNext: null
    onExited: function(code) {
      var next = pendingNext
      pendingNext = null
      if (code !== 0) {
        root.applying = false
        root.lastError = "could not write " + root.currentLuaPath
        console.warn("hyprmoncfg:", root.lastError)
        return
      }
      if (next) next()
    }
  }

  property Process stateWriter: Process {
    property var pendingNext: null
    onExited: function(code) {
      var next = pendingNext
      pendingNext = null
      if (next) next()
    }
  }

  property Process profileWriter: Process {
    property var pendingNext: null
    onExited: function(code) {
      var next = pendingNext
      pendingNext = null
      if (code !== 0) root.lastError = "could not write profile"
      root.reloadProfiles()
      if (next) next()
    }
  }

  property Process profileDeleter: Process {
    onExited: root.reloadProfiles()
  }

  // ---------------------------------------------------------------- applying

  property Process evalProc: Process {
    property string profileName: ""
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(code) {
      root.applying = false
      if (code !== 0) {
        root.lastError = "hyprctl eval failed for '" + profileName + "'"
        console.warn("hyprmoncfg:", root.lastError)
        return
      }
      root.lastError = ""
      root.activeProfile = profileName
      root.writeFile(root.stateWriter, root.statePath,
        JSON.stringify({ active: profileName, appliedAt: new Date().toISOString() }, null, 2) + "\n", null)
      root.applied(profileName)
      settleTimer.restart()
    }
  }

  // Applying a layout makes Hyprland emit its own monitor events. Let them land
  // before the next auto-switch decision, or a two-display apply re-triggers
  // itself once per output.
  property Timer settleTimer: Timer {
    interval: 900
    onTriggered: {
      root.suppressAuto = false
      root.refresh()
    }
  }

  property bool suppressAuto: false

  // Apply a set of resolved entries directly. The editor uses this for a live
  // preview of an unsaved arrangement; applyProfile() routes through it too.
  function applyEntries(entries, name) {
    if (!entries || entries.length === 0) return "no displays to apply"
    var enabled = entries.filter(function(entry) { return entry.enabled !== false })
    if (enabled.length === 0) return "refusing to disable every display"

    root.applying = true
    root.suppressAuto = true
    var lua = Model.luaForEntries(entries, name)
    writeFile(luaWriter, currentLuaPath, lua, function() {
      evalProc.profileName = String(name || "")
      evalProc.command = ["hyprctl", "eval", "dofile(" + Model.luaString(root.currentLuaPath) + ")"]
      evalProc.running = true
    })
    return ""
  }

  function applyProfile(name, reason) {
    var profile = profileByName(name)
    if (!profile) return "no profile named '" + name + "'"
    var entries = Model.resolveProfile(profile, monitors)
    var error = applyEntries(entries, profile.name)
    if (error) return error
    if (notify && reason !== "manual")
      sendNotification("Display profile", profile.name + " · " + (reason || "applied"))
    return ""
  }

  // Decide and act. Called on hotplug, on lid movement, and once at startup.
  function autoApply(reason) {
    if (!autoSwitch || applying || suppressAuto) return
    if (!monitors || monitors.length === 0) return
    var profile = matchingProfile()
    if (!profile) return
    if (profile.name === activeProfile && sameAsLive(profile)) return
    applyProfile(profile.name, reason)
  }

  // True when the live layout already matches the profile, so a redundant
  // modeset (which blanks every screen for a beat) is skipped.
  function sameAsLive(profile) {
    var entries = Model.resolveProfile(profile, monitors)
    var live = {}
    for (var i = 0; i < monitors.length; i++) live[Model.monitorKey(monitors[i])] = monitors[i]
    for (var j = 0; j < entries.length; j++) {
      var entry = entries[j]
      var monitor = live[entry.key]
      if (!monitor) return false
      var enabled = monitor.disabled !== true
      if (enabled !== (entry.enabled !== false)) return false
      if (!enabled) continue
      if (Model.formatPosition(monitor.x, monitor.y) !== String(entry.position)) return false
      var refresh = Number(monitor.refreshRate) || 0
      var mode = Model.normalizeMode(monitor.width + "x" + monitor.height
        + (refresh ? "@" + refresh.toFixed(2) : ""))
      if (mode !== Model.normalizeMode(entry.mode)) return false
      if (Math.abs((Number(monitor.scale) || 1) - (Number(entry.scale) || 1)) > 0.005) return false
      if ((Number(monitor.transform) || 0) !== (Number(entry.transform) || 0)) return false
    }
    return true
  }

  // ---------------------------------------------------------------- profiles

  function saveProfile(name, entries, lid) {
    var trimmed = String(name || "").trim()
    if (!trimmed) return "a profile needs a name"
    var payload = {
      name: trimmed,
      lid: lid || "any",
      createdAt: new Date().toISOString(),
      monitors: (entries || Model.entriesFromMonitors(monitors)).map(function(entry) {
        // availableModes and the live port name are properties of the machine,
        // not of the profile; re-derived on resolve.
        var copy = JSON.parse(JSON.stringify(entry))
        delete copy.availableModes
        delete copy.width
        delete copy.height
        delete copy.internal
        return copy
      })
    }
    var path = profilesDir + "/" + Model.slugify(trimmed) + ".json"
    writeFile(profileWriter, path, JSON.stringify(payload, null, 2) + "\n", null)
    return ""
  }

  function removeProfile(name) {
    var profile = profileByName(name)
    if (!profile) return "no profile named '" + name + "'"
    profileDeleter.command = ["rm", "-f", profilesDir + "/" + Model.slugify(profile.name) + ".json"]
    profileDeleter.running = true
    if (activeProfile === profile.name) activeProfile = ""
    return ""
  }

  function setAutoSwitch(enabled) {
    autoSwitch = enabled === true
    writeFile(stateWriter, configPath,
      JSON.stringify({ autoSwitch: autoSwitch, notify: notify }, null, 2) + "\n", null)
    if (autoSwitch) autoApply("auto re-enabled")
  }

  function sendNotification(headline, description) {
    notifier.command = [binDir + "/notification-send", "-g", "c", headline, description]
    notifier.running = true
  }

  property Process notifier: Process { }

  // ---------------------------------------------------------------- watching

  property Timer hotplugDebounce: Timer {
    interval: 350
    onTriggered: {
      root.refresh()
      autoApplyDelay.restart()
    }
  }

  // hyprctl's answer is what autoApply reasons about, so give the probe a beat
  // to land before deciding.
  property Timer autoApplyDelay: Timer {
    interval: 250
    onTriggered: root.autoApply("displays changed")
  }

  property Connections hyprlandEvents: Connections {
    target: Hyprland

    function onRawEvent(event) {
      var name = String(event.name || "")
      if (name.indexOf("monitor") !== 0 && name !== "configreloaded") return
      root.hotplugDebounce.restart()
    }
  }

  // The lid is not a Hyprland event. One long-lived reader prints only on a
  // change, so the common case costs a `cat` per second and no IPC at all.
  property Process lidWatcher: Process {
    running: true
    command: ["bash", "-c",
      "prev=''; while :; do "
      + "state=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk 'NR==1{print $2}'); "
      + "[[ -n $state ]] || state=open; "
      + "if [[ $state != \"$prev\" ]]; then printf '%s\\n' \"$state\"; prev=$state; fi; "
      + "sleep 1; done"]
    stdout: SplitParser {
      onRead: function(line) {
        var closed = String(line).trim() === "closed"
        if (closed === root.lidClosed) return
        root.lidClosed = closed
        root.hotplugDebounce.restart()
      }
    }
    onExited: lidWatcherRestart.restart()
  }

  property Timer lidWatcherRestart: Timer {
    interval: 2000
    onTriggered: root.lidWatcher.running = true
  }

  // -------------------------------------------------------------------- IPC

  property IpcHandler ipc: IpcHandler {
    target: "hyprmoncfg"

    function status(): string {
      return JSON.stringify({
        active: root.activeProfile,
        auto: root.autoSwitch,
        lid: root.lidClosed ? "closed" : "open",
        setup: root.setupLabel,
        match: root.matchingProfile() ? root.matchingProfile().name : "",
        error: root.lastError,
        displays: root.monitors.map(function(monitor) {
          return {
            name: monitor.name,
            key: Model.monitorKey(monitor),
            label: Model.monitorLabel(monitor),
            enabled: monitor.disabled !== true,
            mode: monitor.width + "x" + monitor.height + "@" + (Number(monitor.refreshRate) || 0).toFixed(2),
            position: Model.formatPosition(monitor.x, monitor.y),
            scale: monitor.scale,
            transform: monitor.transform
          }
        })
      }, null, 2)
    }

    function list(): string {
      if (root.profiles.length === 0) return "no profiles saved"
      return root.profiles.map(function(profile) {
        var mark = profile.name === root.activeProfile ? "* " : "  "
        var displays = (profile.monitors || []).map(function(entry) { return entry.label }).join(" + ")
        var lid = String(profile.lid || "any")
        return mark + profile.name + "\t" + displays + (lid === "any" ? "" : "\t(lid " + lid + ")")
      }).join("\n")
    }

    function apply(name: string): string {
      var error = root.applyProfile(name, "manual")
      return error ? "error: " + error : "applied " + name
    }

    function save(name: string): string {
      var error = root.saveProfile(name, Model.entriesFromMonitors(root.monitors), "any")
      return error ? "error: " + error : "saved " + name
    }

    function remove(name: string): string {
      var error = root.removeProfile(name)
      return error ? "error: " + error : "removed " + name
    }

    function auto(): string {
      root.suppressAuto = false
      root.autoApply("manual")
      var profile = root.matchingProfile()
      return profile ? "matched " + profile.name : "no profile matches " + root.setupLabel
    }

    function setAuto(enabled: string): string {
      root.setAutoSwitch(String(enabled) !== "false" && String(enabled) !== "0")
      return root.autoSwitch ? "auto-switching on" : "auto-switching off"
    }

    function reload(): string {
      root.refresh()
      root.reloadProfiles()
      return "ok"
    }
  }

  Component.onCompleted: {
    refresh()
    settingsReader.running = true
  }
}

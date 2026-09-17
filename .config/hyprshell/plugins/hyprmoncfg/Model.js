// hyprmoncfg — pure model logic. No QML types in here, so the whole profile
// pipeline (identity, matching, Lua generation, snapping) stays testable with
// plain `qmlscene`-free reasoning and is shared by the panel and the service.

// ------------------------------------------------------------------ identity

function text(value) {
  return String(value === null || value === undefined ? "" : value).trim()
}

// A monitor's identity is make/model/serial, never the port it happens to be
// plugged into: the same dock hands out DP-1 or DP-2 depending on the order
// the displays woke up, so a port-keyed profile picks the wrong screen about
// half the time. EDID-less outputs (some KVMs, virtual sinks) fall back to the
// description and finally the port, which at least stays stable per session.
function monitorKey(monitor) {
  if (!monitor) return ""
  var parts = [text(monitor.make), text(monitor.model), text(monitor.serial)]
    .filter(function(part) { return part.length > 0 })
  if (parts.length > 0) return parts.join("|")
  return text(monitor.description) || text(monitor.name)
}

function monitorLabel(monitor) {
  if (!monitor) return ""
  var label = (text(monitor.make) + " " + text(monitor.model)).trim()
  if (label.length > 0) return label
  return text(monitor.description) || text(monitor.name)
}

function isInternal(monitor) {
  return /^(eDP|LVDS|DSI)-/i.test(text(monitor && monitor.name))
}

// Stable, order-independent description of what is plugged in right now.
function setupKey(monitors) {
  return (monitors || []).map(monitorKey).filter(function(key) { return key.length > 0 })
    .sort().join("\n")
}

function setupLabel(monitors) {
  var names = (monitors || []).map(monitorLabel).filter(function(n) { return n.length > 0 }).sort()
  if (names.length === 0) return "no displays"
  return names.join(" + ")
}

function slugify(name) {
  var slug = text(name).toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "")
  return slug.length > 0 ? slug : "profile"
}

// ------------------------------------------------------------------ geometry

function parseMode(mode) {
  var match = /^(\d+)x(\d+)(?:@([0-9.]+))?/.exec(text(mode))
  if (!match) return null
  return {
    width: parseInt(match[1], 10),
    height: parseInt(match[2], 10),
    refresh: match[3] ? parseFloat(match[3]) : 0
  }
}

// Hyprland reports "1920x1080@144.00Hz" in availableModes but wants
// "1920x1080@144.00" in a monitor spec.
function normalizeMode(mode) {
  var parsed = parseMode(mode)
  if (!parsed) return text(mode)
  if (!parsed.refresh) return parsed.width + "x" + parsed.height
  return parsed.width + "x" + parsed.height + "@" + parsed.refresh.toFixed(2)
}

function modeLabel(mode) {
  var parsed = parseMode(mode)
  if (!parsed) return text(mode)
  if (!parsed.refresh) return parsed.width + " × " + parsed.height
  return parsed.width + " × " + parsed.height + "  " + Math.round(parsed.refresh) + " Hz"
}

// Transforms 1/3/5/7 are the 90°/270° rotations, which swap the logical axes.
function transformSwapsAxes(transform) {
  return (Number(transform) || 0) % 2 === 1
}

// The size a display occupies in Hyprland's layout coordinate space: pixels
// divided by scale, axes swapped if it is rotated on its side.
function logicalSize(entry) {
  var parsed = parseMode(entry && entry.mode)
  var width = parsed ? parsed.width : Number(entry && entry.width) || 0
  var height = parsed ? parsed.height : Number(entry && entry.height) || 0
  var scale = Number(entry && entry.scale) || 1
  if (scale <= 0) scale = 1
  var logicalWidth = Math.round(width / scale)
  var logicalHeight = Math.round(height / scale)
  if (transformSwapsAxes(entry && entry.transform)) {
    var swap = logicalWidth
    logicalWidth = logicalHeight
    logicalHeight = swap
  }
  return { width: logicalWidth, height: logicalHeight }
}

function parsePosition(position) {
  var match = /^(-?\d+)x(-?\d+)$/.exec(text(position))
  if (!match) return { x: 0, y: 0 }
  return { x: parseInt(match[1], 10), y: parseInt(match[2], 10) }
}

function formatPosition(x, y) {
  return Math.round(x) + "x" + Math.round(y)
}

// Bounding box of every enabled entry, in layout coordinates.
function bounds(entries) {
  var box = null
  for (var i = 0; i < (entries || []).length; i++) {
    var entry = entries[i]
    if (!entry || entry.enabled === false) continue
    var size = logicalSize(entry)
    var position = parsePosition(entry.position)
    var rect = {
      left: position.x,
      top: position.y,
      right: position.x + size.width,
      bottom: position.y + size.height
    }
    if (!box) box = rect
    else {
      box.left = Math.min(box.left, rect.left)
      box.top = Math.min(box.top, rect.top)
      box.right = Math.max(box.right, rect.right)
      box.bottom = Math.max(box.bottom, rect.bottom)
    }
  }
  return box || { left: 0, top: 0, right: 1920, bottom: 1080 }
}

// Snap a dragged display to its neighbours: edges flush (side by side, stacked)
// and axes aligned (tops, centers, bottoms level). Returns the adjusted
// position plus the guide lines worth drawing, so the editor can show why it
// jumped. `threshold` is in layout pixels.
function snapPosition(entries, movingIndex, x, y, threshold) {
  var moving = entries[movingIndex]
  var size = logicalSize(moving)
  var result = { x: Math.round(x), y: Math.round(y), guideX: null, guideY: null }
  var bestX = threshold + 1
  var bestY = threshold + 1

  function considerX(candidate, guide) {
    var distance = Math.abs(candidate - x)
    if (distance > threshold || distance >= bestX) return
    bestX = distance
    result.x = Math.round(candidate)
    result.guideX = guide
  }

  function considerY(candidate, guide) {
    var distance = Math.abs(candidate - y)
    if (distance > threshold || distance >= bestY) return
    bestY = distance
    result.y = Math.round(candidate)
    result.guideY = guide
  }

  for (var i = 0; i < entries.length; i++) {
    if (i === movingIndex) continue
    var other = entries[i]
    if (!other || other.enabled === false) continue
    var otherSize = logicalSize(other)
    var otherPosition = parsePosition(other.position)
    var left = otherPosition.x
    var top = otherPosition.y
    var right = left + otherSize.width
    var bottom = top + otherSize.height

    // Flush against the left/right edges, then aligned left/right/center.
    considerX(right, right)
    considerX(left - size.width, left)
    considerX(left, left)
    considerX(right - size.width, right)
    considerX(left + (otherSize.width - size.width) / 2, left + otherSize.width / 2)

    considerY(bottom, bottom)
    considerY(top - size.height, top)
    considerY(top, top)
    considerY(bottom - size.height, bottom)
    considerY(top + (otherSize.height - size.height) / 2, top + otherSize.height / 2)
  }

  return result
}

// Hyprland refuses a layout with a gap or an overlap in places, and a gap
// leaves the cursor unable to cross. After a drag, pull everything back so the
// top-left of the arrangement sits at 0,0 — Hyprland's own convention.
// Shifted entries are replaced with fresh objects, not mutated in place, so
// QML bindings that hold the old reference still see the new position.
function normalizeOrigin(entries) {
  var box = bounds(entries)
  if (box.left === 0 && box.top === 0) return entries
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (!entry) continue
    var position = parsePosition(entry.position)
    entries[i] = Object.assign({}, entry, {
      position: formatPosition(position.x - box.left, position.y - box.top)
    })
  }
  return entries
}

function overlaps(entries) {
  var rects = []
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (!entry || entry.enabled === false) continue
    var size = logicalSize(entry)
    var position = parsePosition(entry.position)
    rects.push({
      name: entry.output || entry.label,
      left: position.x,
      top: position.y,
      right: position.x + size.width,
      bottom: position.y + size.height
    })
  }
  var clashes = []
  for (var a = 0; a < rects.length; a++) {
    for (var b = a + 1; b < rects.length; b++) {
      if (rects[a].left < rects[b].right && rects[b].left < rects[a].right
          && rects[a].top < rects[b].bottom && rects[b].top < rects[a].bottom)
        clashes.push(rects[a].name + " / " + rects[b].name)
    }
  }
  return clashes
}

// ------------------------------------------------------------------- profiles

// Snapshot the live `hyprctl -j monitors all` output as profile entries.
function entriesFromMonitors(monitors) {
  return (monitors || []).map(function(monitor) {
    var refresh = Number(monitor.refreshRate) || 0
    var mode = monitor.width + "x" + monitor.height + (refresh ? "@" + refresh.toFixed(2) : "")
    return {
      key: monitorKey(monitor),
      label: monitorLabel(monitor),
      output: text(monitor.name),
      enabled: monitor.disabled !== true,
      mode: normalizeMode(mode),
      position: formatPosition(monitor.x, monitor.y),
      scale: Number(monitor.scale) || 1,
      transform: Number(monitor.transform) || 0,
      mirror: text(monitor.mirrorOf) === "none" ? "" : text(monitor.mirrorOf),
      vrr: monitor.vrr === true,
      cm: text(monitor.colorManagementPreset) || "auto",
      sdrBrightness: Number(monitor.sdrBrightness) || 1,
      bitdepth: 0,
      workspaces: [],
      defaultWorkspace: "",
      availableModes: (monitor.availableModes || []).map(normalizeMode),
      width: Number(monitor.width) || 0,
      height: Number(monitor.height) || 0,
      internal: isInternal(monitor)
    }
  })
}

function newProfile(name, monitors) {
  return {
    name: text(name),
    lid: "any",
    createdAt: new Date().toISOString(),
    monitors: entriesFromMonitors(monitors)
  }
}

// Re-attach a saved profile to the live outputs. Saved entries carry an EDID
// key; the live monitor with that key supplies the port name to drive. Entries
// whose display is not plugged in are dropped, and live displays the profile
// never heard of are appended enabled so a new screen is never left dark.
function resolveProfile(profile, monitors) {
  var byKey = {}
  for (var i = 0; i < (monitors || []).length; i++) {
    var key = monitorKey(monitors[i])
    if (key) byKey[key] = monitors[i]
  }

  var resolved = []
  var claimed = {}
  var saved = (profile && profile.monitors) || []
  for (var j = 0; j < saved.length; j++) {
    var entry = saved[j]
    var live = byKey[text(entry.key)]
    if (!live) continue
    claimed[text(entry.key)] = true
    var copy = JSON.parse(JSON.stringify(entry))
    copy.output = text(live.name)
    copy.availableModes = (live.availableModes || []).map(normalizeMode)
    copy.internal = isInternal(live)
    resolved.push(copy)
  }

  var extras = entriesFromMonitors(monitors).filter(function(entry) { return !claimed[entry.key] })
  return resolved.concat(extras)
}

// How well a profile fits what is plugged in. -1 means "not applicable".
// An exact set match beats a partial one, and a profile that names a lid state
// beats an equally-good profile that does not care, so "lid closed, docked" can
// override plain "docked" without either having to know about the other.
function profileScore(profile, monitors, lidClosed) {
  if (!profile) return -1
  var lid = text(profile.lid) || "any"
  if (lid === "open" && lidClosed) return -1
  if (lid === "closed" && !lidClosed) return -1

  var live = {}
  var liveCount = 0
  for (var i = 0; i < (monitors || []).length; i++) {
    var key = monitorKey(monitors[i])
    if (!key) continue
    live[key] = true
    liveCount++
  }

  var savedKeys = ((profile.monitors) || []).map(function(entry) { return text(entry.key) })
    .filter(function(key) { return key.length > 0 })
  if (savedKeys.length === 0) return -1
  for (var j = 0; j < savedKeys.length; j++) {
    if (!live[savedKeys[j]]) return -1
  }

  var score = savedKeys.length * 10
  if (savedKeys.length === liveCount) score += 100
  if (lid !== "any") score += 5
  return score
}

function bestProfile(profiles, monitors, lidClosed) {
  var best = null
  var bestScore = -1
  for (var i = 0; i < (profiles || []).length; i++) {
    var score = profileScore(profiles[i], monitors, lidClosed)
    if (score <= bestScore) continue
    bestScore = score
    best = profiles[i]
  }
  return best
}

// ------------------------------------------------------------------ Lua emit

function luaString(value) {
  return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
}

function luaNumber(value) {
  var number = Number(value)
  if (!isFinite(number)) return "0"
  return String(Math.round(number * 1000) / 1000)
}

// Hyprland 0.55+ configs are Lua, so `hyprctl keyword` is refused ("keyword
// can't work with non-legacy parsers"). The profile is emitted as a Lua chunk
// instead, written to disk and pulled in with `hyprctl eval 'dofile(...)'` —
// which also makes the same file loadable from hyprland.lua at startup, so a
// profile survives a compositor restart without a second code path.
function luaForEntries(entries, profileName) {
  var lines = []
  lines.push("-- Generated by hyprmoncfg. Do not edit; it is rewritten on every apply.")
  lines.push("-- Profile: " + text(profileName || "unnamed"))
  lines.push("-- Written: " + new Date().toISOString())
  lines.push("")

  var workspaceRules = []
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    var output = text(entry.output)
    if (!output) continue

    if (entry.enabled === false) {
      lines.push("hl.monitor({ output = " + luaString(output) + ", disabled = true })")
      continue
    }

    var fields = []
    fields.push("output = " + luaString(output))
    fields.push("mode = " + luaString(text(entry.mode) || "preferred"))
    fields.push("position = " + luaString(text(entry.position) || "auto"))
    fields.push("scale = " + luaNumber(entry.scale || 1))
    fields.push("transform = " + String(Math.round(Number(entry.transform) || 0)))
    if (text(entry.mirror)) fields.push("mirror = " + luaString(text(entry.mirror)))
    if (entry.vrr === true) fields.push("vrr = 1")
    var cm = text(entry.cm)
    if (cm && cm !== "auto") fields.push("cm = " + luaString(cm))
    if (Number(entry.bitdepth) === 10) fields.push("bitdepth = 10")
    var sdr = Number(entry.sdrBrightness)
    if (isFinite(sdr) && sdr > 0 && Math.abs(sdr - 1) > 0.001 && cm.indexOf("hdr") === 0)
      fields.push("sdrbrightness = " + luaNumber(sdr))
    lines.push("hl.monitor({ " + fields.join(", ") + " })")

    var workspaces = entry.workspaces || []
    for (var w = 0; w < workspaces.length; w++) {
      var workspace = text(workspaces[w])
      if (!workspace) continue
      var rule = ["workspace = " + luaString(workspace), "monitor = " + luaString(output), "persistent = true"]
      if (workspace === text(entry.defaultWorkspace)) rule.push("default = true")
      workspaceRules.push("hl.workspace_rule({ " + rule.join(", ") + " })")
    }
  }

  if (workspaceRules.length > 0) {
    lines.push("")
    lines = lines.concat(workspaceRules)
  }
  lines.push("")
  return lines.join("\n")
}

// Displays parsed out of a workspace field: "1-5" expands, "1,2,special:x"
// splits. Anything unparseable is passed through verbatim so named workspaces
// keep working.
function parseWorkspaces(input) {
  var out = []
  var parts = text(input).split(/[,\s]+/)
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i].trim()
    if (!part) continue
    var range = /^(\d+)-(\d+)$/.exec(part)
    if (range) {
      var from = parseInt(range[1], 10)
      var to = parseInt(range[2], 10)
      if (from > to) { var swap = from; from = to; to = swap }
      for (var n = from; n <= to && n - from < 64; n++) out.push(String(n))
      continue
    }
    out.push(part)
  }
  return out
}

function formatWorkspaces(workspaces) {
  return (workspaces || []).join(", ")
}

// -------------------------------------------------------------------- scales

// Hyprland only accepts a scale that divides the mode into whole logical
// pixels; anything else is silently rounded to one that does, and the layout
// then no longer matches what the editor drew. Same arithmetic the built-in
// Display panel uses, so both offer the same set.
function gcd(a, b) {
  while (b) {
    var remainder = a % b
    a = b
    b = remainder
  }
  return a
}

function normalizeScale(scale) {
  var number = parseFloat(String(scale || ""))
  if (!isFinite(number)) return ""
  return String(Math.round(number * 100) / 100)
}

function cleanScale(scale, width, height) {
  var requested = Number(scale)
  var modeWidth = Number(width)
  var modeHeight = Number(height)
  if (!isFinite(requested) || !isFinite(modeWidth) || !isFinite(modeHeight)
      || requested <= 0 || modeWidth <= 0 || modeHeight <= 0) return ""

  var divisor = gcd(Math.round(modeWidth * 120), Math.round(modeHeight * 120))
  var scaleUnits = Math.round(requested * 120)
  if (scaleUnits > divisor) scaleUnits = divisor
  while (divisor % scaleUnits !== 0) scaleUnits++
  return normalizeScale(scaleUnits / 120)
}

function availableScales(entry) {
  var presets = [1, 1.2, 1.25, 1.5, 1.6, 1.75, 2, 2.5, 3]
  var parsed = parseMode(entry && entry.mode)
  var width = parsed ? parsed.width : Number(entry && entry.width) || 0
  var height = parsed ? parsed.height : Number(entry && entry.height) || 0
  if (width <= 0 || height <= 0) return presets.map(String)

  var seen = {}
  var out = []
  for (var i = 0; i < presets.length; i++) {
    var effective = cleanScale(presets[i], width, height)
    if (!effective || seen[effective]) continue
    seen[effective] = true
    out.push(effective)
  }
  // Whatever the display is set to now always stays selectable, even if it is
  // not one of the presets (a profile written by hand, or a Hyprland default).
  var current = normalizeScale(entry && entry.scale)
  if (current && !seen[current]) out.push(current)
  return out.sort(function(a, b) { return Number(a) - Number(b) })
}

function scaleLabel(scale) {
  var number = Number(scale)
  if (!isFinite(number)) return String(scale)
  if (Math.abs(number - 1) < 0.001) return "100%  (1×)"
  return Math.round(number * 100) + "%  (" + normalizeScale(number) + "×)"
}

// ---------------------------------------------------------------- brightness

// Same clamp as the brightness helpers: 1..100, rounding, never NaN.
function clampBrightness(value) {
  var number = Number(value)
  if (!isFinite(number)) return 1
  return Math.max(1, Math.min(100, Math.round(number)))
}

var TRANSFORM_LABELS = ["0°", "90°", "180°", "270°"]

var COLOR_PRESETS = [
  { value: "auto", label: "Auto" },
  { value: "srgb", label: "sRGB" },
  { value: "wide", label: "Wide gamut" },
  { value: "edid", label: "From EDID" },
  { value: "hdr", label: "HDR" },
  { value: "hdredid", label: "HDR (EDID)" }
]

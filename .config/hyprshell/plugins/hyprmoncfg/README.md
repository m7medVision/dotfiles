# hyprmoncfg

Multi-monitor layouts for Hyprland: arrange your displays in a visual editor,
save the arrangement as a profile, and have it switch itself back on when those
displays reappear.

A plugin for the hyprshell desktop (`~/.config/hyprshell/plugins/hyprmoncfg`).

## Why profiles instead of a static config

`monitors.lua` describes one arrangement. Undock, plug into a different desk,
close the lid — and it is wrong until you edit it. hyprmoncfg keeps one profile
per situation and picks the right one on its own.

Profiles match on each display's **make, model and serial**, not on the port it
happens to be plugged into. The same monitor is `DP-1` on one dock and `DP-2` on
the next; the profile follows the screen, not the cable.

## What it does

- **Automatic switching** on hotplug, on lid open/close, and at login.
- **Visual editor** — drag a display and it snaps flush against its neighbours,
  or aligns tops, centres and bottoms. Overlaps are called out before you apply.
- **Per-display settings** — resolution, scale (only the scales Hyprland can
  actually honour for that mode are offered), rotation, mirroring, colour
  preset, VRR, and brightness.
- **Workspace planning** — pin workspaces to a display (`1-5` expands), with an
  optional default workspace per screen.
- **Lid-aware profiles** — a profile can require the lid open, closed, or not
  care. A lid-specific profile wins over an otherwise equally good one.

## Install

The plugin itself is enabled in `~/.config/hyprshell/shell.json` (`plugins[]`).
The CLI is put on `PATH` with a symlink:

```
ln -sf ~/.config/hyprshell/plugins/hyprmoncfg/bin/hyprmoncfg ~/.local/bin/hyprmoncfg
hyprmoncfg manage
```

## Using it

Open the editor:

```
hyprmoncfg                 # or SUPER + CTRL + D
```

or click the displays icon in the bar (right section, next to the tray).

Arrange, name the profile, hit **Save**, then **Apply**. From then on, plugging
those displays in brings the layout back. **Apply** under a name that already
owns a profile rewrites that profile too — otherwise the next auto-switch would
bring back the arrangement you just replaced.

From the command line:

```
hyprmoncfg list            # saved profiles, * marks the active one
hyprmoncfg status          # displays, lid state, which profile matches
hyprmoncfg save docked     # snapshot the current arrangement
hyprmoncfg apply docked
hyprmoncfg remove docked
hyprmoncfg auto            # re-run matching now
hyprmoncfg auto off        # stop switching automatically
```

## How it applies a layout

Hyprland has been Lua-configured since 0.55, and `hyprctl keyword` refuses to
run against the Lua parser ("keyword can't work with non-legacy parsers"). So a
profile is emitted as a Lua chunk to `~/.config/hyprmoncfg/current.lua` and
pulled in with `hyprctl eval 'dofile(...)'`.

The same file is what `hyprmoncfg manage` wires into `hyprland.lua`, so a
profile survives a compositor restart through the same code path that applied it
live — there is no second, subtly different way to render a profile.

```
hyprmoncfg manage          # load the active profile at Hyprland startup
hyprmoncfg unmanage        # remove that block, and stop auto-switching
```

`manage` appends a marked block at the very end of `hyprland.lua`, after
`require("monitors")`, so the active profile wins over any static `hl.monitor()`
call. `unmanage` takes the block back out and leaves the file as it was.

## Where things live

| Path | What |
| --- | --- |
| `~/.config/hyprmoncfg/profiles/*.json` | one file per profile |
| `~/.config/hyprmoncfg/current.lua` | the last applied layout, as Lua |
| `~/.config/hyprmoncfg/state.json` | which profile is active |
| `~/.config/hyprmoncfg/config.json` | auto-switch and notification settings |

## Structure

| File | What |
| --- | --- |
| `Service.qml` | the daemon: hotplug and lid watching, profile matching, applying, IPC |
| `Panel.qml` | the editor overlay |
| `DisplaysWidget.qml` | the bar icon that opens the editor |
| `Model.js` | identity, matching, geometry/snapping, Lua emission — no QML |
| `bin/hyprmoncfg` | CLI, plus the `hyprland.lua` manage/unmanage wiring |

The daemon runs inside the shell rather than as its own systemd unit: the shell
already holds a Hyprland event socket open, and a second process would only
duplicate that plumbing and race it on hotplug.

## Removing it

```
hyprmoncfg unmanage
shell-ipc-run shell setPluginEnabled hyprmoncfg false
```

Saved profiles are left alone.

## Prior art

Modelled on [omarchy-hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg)
by crmne, rebuilt against hyprshell's plugin API and Hyprland's Lua config.

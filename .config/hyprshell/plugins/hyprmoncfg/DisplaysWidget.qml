import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

// Bar entry for the displays editor: one icon, one click, the panel opens.
// Modelled on upstream's BarWidget.qml — the icon counts the screens so a
// multi-monitor setup is visible at a glance — but toggles this shell's own
// panel IPC instead of loading the panel inline.
BarWidget {
  id: root
  moduleName: "hyprmoncfg"

  property int monitorCount: Quickshell.screens.length

  function togglePanel() {
    if (root.bar) root.bar.run("shell-ipc-run shell toggle hyprmoncfg '{}'")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.monitorCount > 1 ? "\uf2d8" : "\uf108"
    fontFamily: Style.font.family
    fontSize: Style.bar.iconFont
    tooltipText: root.monitorCount > 1
      ? "Displays · " + root.monitorCount + " screens"
      : "Displays"
    onPressed: function() { root.togglePanel() }
  }
}

import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "raw.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\udb80\udf5c"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("shell-ipc-run shell toggle raw.menu '{\"menu\":\"root\"}'")
    }
  }
}

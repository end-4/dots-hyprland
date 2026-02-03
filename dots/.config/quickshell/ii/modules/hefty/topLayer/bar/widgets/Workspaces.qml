import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as IIBar
import qs.modules.common as C

IIBar.Workspaces {
    id: root
    vertical: C.Config.options.bar.vertical
    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
}

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as IIBar
import qs.modules.common as C

IIBar.Workspaces {
    id: root
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    implicitWidth: root.vertical ? C.Appearance.sizes.verticalBarWidth : (root.workspaceButtonWidth * root.workspacesShown - 2)
    implicitHeight: root.vertical ? (root.workspaceButtonWidth * root.workspacesShown - 2) : C.Appearance.sizes.barHeight
}

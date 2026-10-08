import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root

    Component.onCompleted: {
        Network.updateVpnList();
    }

    WPanelPageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                HeaderRow {
                    id: headerRow
                    Layout.fillWidth: true
                    title: Translation.tr("VPN")
                }

                StyledListView {
                    id: listView
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    animateAppearance: false

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true
                    spacing: 4

                    model: ScriptModel {
                        values: Network.vpnConnectionsVars
                    }
                    delegate: WVpnConnectionItem {
                        required property VpnConnection modelData
                        vpnConnection: modelData
                        width: ListView.view.width
                    }
                }
            }
        }

        WPanelSeparator {}

        FooterRectangle {
            WTextButton {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }
                text: Translation.tr("More Internet settings")
                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarLeft", "toggle"]);
                    Quickshell.execDetached(["bash", "-c", Config.options.apps.network]);
                }
            }
        }
    }
}

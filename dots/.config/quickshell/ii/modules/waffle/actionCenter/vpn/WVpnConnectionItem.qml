import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

ExpandableChoiceButton {
    id: root
    required property VpnConnection vpnConnection

    contentItem: RowLayout {
        id: contentItem
        spacing: 12

        FluentIcon { // Duotone hack
            Layout.bottomMargin: 2
            Layout.alignment: Qt.AlignTop
            icon: vpnConnection?.isActive ? "lock-closed-filled" : "lock-open"
            implicitSize: 30
            color: Looks.colors.inactiveIcon
        }

        ColumnLayout {
            Layout.topMargin: statusText.visible ? 4 : 7
            Layout.bottomMargin: 4
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 1

            Behavior on Layout.topMargin {
                animation: Looks.transition.move.createObject(this)
            }

            WText { // vpn name
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.large
                text: root.vpnConnection?.name ?? Translation.tr("Unknown")
                textFormat: Text.PlainText
            }
            WText { // Status
                id: statusText
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.vpnConnection?.isActive ? Translation.tr("Connected") : Translation.tr("Disconnected")
                font.pixelSize: Looks.font.pixelSize.large
                color: Looks.colors.subfg
                visible: root.vpnConnection?.isActive || root.expanded
                Behavior on opacity {
                    animation: Looks.transition.opacity.createObject(this)
                }
            }

            WButton {
                Layout.alignment: Qt.AlignRight
                horizontalAlignment: Text.AlignHCenter
                visible: root.expanded
                checked: !(root.vpnConnection?.isActive ?? false)
                colBackground: Looks.colors.bg2
                colBackgroundHover: Looks.colors.bg2Hover
                colBackgroundActive: Looks.colors.bg2Active
                implicitHeight: 30
                implicitWidth: 148
                text: root.vpnConnection?.isActive ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    Network.toggleVpnConnection(root.vpnConnection?.name, root.vpnConnection?.isActive);
                }
            }
        }
    }
}

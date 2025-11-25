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
    required property WifiAccessPoint wifiNetwork

    contentItem: RowLayout {
        id: contentItem
        spacing: 12

        FluentIcon { // Duotone hack
            Layout.bottomMargin: 2
            Layout.alignment: Qt.AlignTop
            property int strength: root.wifiNetwork?.strength ?? 0
            icon: "wifi-1"
            implicitSize: 30
            color: Looks.colors.inactiveIcon

            FluentIcon { // Signal
                property int strength: root.wifiNetwork?.strength ?? 0
                icon: WIcons.wifiIconForStrength(strength)
                implicitSize: 30

                FluentIcon { // Security
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    visible: root?.wifiNetwork?.isSecure ?? false
                    icon: "lock-closed"
                    filled: true
                    implicitSize: 14           
                }
            }
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

            WText { // Network name
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.large
                text: root.wifiNetwork?.ssid ?? Translation.tr("Unknown")
            }
            WText { // Status
                id: statusText
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.wifiNetwork?.active ? Translation.tr("Connected") : root.wifiNetwork?.isSecure ? Translation.tr("Secured") : Translation.tr("Not secured")
                font.pixelSize: Looks.font.pixelSize.large
                color: Looks.colors.subfg
                visible: root.wifiNetwork?.active || root.expanded
                Behavior on opacity {
                    animation: Looks.transition.opacity.createObject(this)
                }
            }

            WButton {
                Layout.alignment: Qt.AlignRight
                horizontalAlignment: Text.AlignHCenter
                visible: root.expanded
                checked: !(root.wifiNetwork?.active ?? false)
                colBackground: Looks.colors.bg2
                colBackgroundHover: Looks.colors.bg2Hover
                colBackgroundActive: Looks.colors.bg2Active
                implicitHeight: 30
                implicitWidth: 148
                text: root.wifiNetwork?.active ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (root.wifiNetwork?.active) {
                        Network.disconnectWifiNetwork();
                    } else {
                        Network.connectToWifiNetwork(root.wifiNetwork);
                    }
                }
            }
        }
    }
}

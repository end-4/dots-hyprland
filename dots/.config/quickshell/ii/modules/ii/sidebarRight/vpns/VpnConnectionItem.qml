import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.services.network
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property VpnConnection vpnConnection
    enabled: !Network.vpnScanning

    active: vpnConnection?.isActive ?? false
    onClicked: {
        if (vpnConnection) {
            vpnConnection.toggle();
        }
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: {
                    if (!root.vpnConnection) return "vpn_lock";
                    return root.vpnConnection.isActive ? "link" : "link_off";
                }
                color: root.vpnConnection?.isActive ?
                       Appearance.m3colors.m3primary :
                       Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                Layout.topMargin: 4

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.vpnConnection?.name ?? Translation.tr("Unknown VPN")
                    font.bold: root.vpnConnection?.isActive ?? false
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3outline
                    elide: Text.ElideRight
                    text: {
                        if (!root.vpnConnection) return Translation.tr("Loading...");
                        if (root.vpnConnection.isActive) {
                            return ("%1 • %2").arg(Translation.tr("Active")).arg(root.vpnConnection.device || Translation.tr("No device"));
                        } else {
                            return ("%1 • %2").arg(Translation.tr("Inactive")).arg(root.vpnConnection.type || "VPN");
                        }
                    }
                }

            }

            MaterialSymbol {
                visible: root.vpnConnection !== null
                text: {
                    if (!root.vpnConnection) return "";
                    return root.vpnConnection.isActive ? "check_circle" : "radio_button_unchecked";
                }
                iconSize: Appearance.font.pixelSize.larger
                color: root.vpnConnection?.isActive ?
                       Appearance.m3colors.m3primary :
                       Appearance.colors.colOnSurfaceVariant
            }
        }

        ColumnLayout {
            id: vpnActions
            Layout.topMargin: 8
            visible: root.vpnConnection?.isActive ?? false

            RowLayout {
                DialogButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("Disconnect")
                    colBackground: Appearance.m3colors.m3errorContainer
                    colBackgroundHover: Qt.darker(Appearance.m3colors.m3errorContainer, 1.1)
                    colRipple: Qt.darker(Appearance.m3colors.m3errorContainer, 1.2)
                    colText: Appearance.m3colors.m3onErrorContainer
                    onClicked: {
                        if (root.vpnConnection) {
                            root.vpnConnection.toggle();
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

}
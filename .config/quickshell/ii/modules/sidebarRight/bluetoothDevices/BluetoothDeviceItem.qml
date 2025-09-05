import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    
    component ActionButton: DialogButton {
        colBackground: Appearance.colors.colPrimary
        colBackgroundHover: Appearance.colors.colPrimaryHover
        colRipple: Appearance.colors.colPrimaryActive
        colText: Appearance.colors.colOnPrimary
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.device?.name || Translation.tr("Unknown device")
                }
                StyledText {
                    visible: (root.device?.connected || root.device?.paired) ?? false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        if (!root.device?.paired) return "";
                        let statusText = root.device?.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (!root.device?.batteryAvailable) return statusText;
                        statusText += ` • ${Math.round(root.device?.battery * 100)}%`;
                        return statusText;
                    }
                }
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer3
                rotation: root.expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.topMargin: 8
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                buttonText: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect();
                    } else {
                        root.device.connect();
                    }
                }
            }
            ActionButton {
                visible: root.device?.paired ?? false
                colBackground: Appearance.colors.colError
                colBackgroundHover: Appearance.colors.colErrorHover
                colRipple: Appearance.colors.colErrorActive
                colText: Appearance.colors.colOnError

                buttonText: Translation.tr("Forget")
                onClicked: {
                    root.device?.forget();
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}

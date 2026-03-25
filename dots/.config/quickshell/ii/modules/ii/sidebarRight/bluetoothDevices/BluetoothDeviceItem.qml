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
        colRipple: Appearance.colors.colPrimaryHover
        colText: Appearance.colors.colOnPrimary
    }


    buttonRadius: 20

    colBackground: expanded ? Appearance.colors.colPrimaryContainer : "transparent"
    colBackgroundHover: expanded ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3Hover

    contentItem: ColumnLayout {
            anchors {
                fill: parent
                topMargin: root.verticalPadding
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 0

            RowLayout {
                spacing: 16

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: root.device?.icon.includes('input') ? Appearance.colors.colPrimary 
                    : root.device?.icon.includes('audio') ? Appearance.colors.colTertiary
                    : Appearance.colors.colSecondary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.larger
                        text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                        color: root.device?.icon.includes('input') ? Appearance.colors.colOnPrimary 
                        : root.device?.icon.includes('audio') ? Appearance.colors.colOnTertiary
                        : Appearance.colors.colOnSecondary
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        text: root.device?.name || Translation.tr("Unknown device")
                        textFormat: Text.PlainText
                    }
                    StyledText {
                        visible: (root.device?.connected || root.device?.paired) ?? false
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
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

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    property bool actionInProgress: false
    property bool actionWasConnect: false
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    onDeviceChanged: clearActionFeedback()

    function clearActionFeedback() {
        actionInProgress = false;
        actionFeedbackTimeout.stop();
    }

    Connections {
        target: root.device
        ignoreUnknownSignals: true

        function onConnectedChanged() {
            root.clearActionFeedback();
        }

        function onPairedChanged() {
            root.clearActionFeedback();
        }
    }

    Timer {
        id: actionFeedbackTimeout
        interval: 10000
        onTriggered: root.actionInProgress = false
    }

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
                    textFormat: Text.PlainText
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
            Item {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "bluetooth_connected"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colPrimary
                    opacity: root.actionInProgress ? 1 : 0
                    scale: root.actionInProgress ? pulseAnim.pulseScale : 0.8

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    Behavior on scale {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    SequentialAnimation {
                        id: pulseAnim
                        property real pulseScale: 1
                        running: root.actionInProgress
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: pulseAnim
                            property: "pulseScale"
                            from: 0.9
                            to: 1.08
                            duration: 450
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            target: pulseAnim
                            property: "pulseScale"
                            from: 1.08
                            to: 0.9
                            duration: 450
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
            ActionButton {
                enabled: !root.actionInProgress
                buttonText: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (root.device?.connected) {
                        root.actionWasConnect = false;
                        root.actionInProgress = true;
                        actionFeedbackTimeout.restart();
                        root.device.disconnect();
                    } else {
                        root.actionWasConnect = true;
                        root.actionInProgress = true;
                        actionFeedbackTimeout.restart();
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

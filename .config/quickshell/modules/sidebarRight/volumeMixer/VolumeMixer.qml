import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire


Item {
    id: root
    property bool showDeviceSelector: false
    property bool deviceSelectorInput
    property int dialogMargins: 16
    property PwNode selectedDevice

    function showDeviceSelectorDialog(input: bool) {
        root.selectedDevice = null
        root.showDeviceSelector = true
        root.deviceSelectorInput = input
    }

    Keys.onPressed: (event) => {
        // Close dialog on pressing Esc if open
        if (event.key === Qt.Key_Escape && root.showDeviceSelector) {
            root.showDeviceSelector = false
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: volumeMixerColumnLayout.height

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: flickable.width
                        height: flickable.height
                        radius: Appearance.rounding.normal
                    }
                }

                ColumnLayout {
                    id: volumeMixerColumnLayout
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 10

                    // Get a list of nodes that output to the default sink
                    PwNodeLinkTracker {
                        id: linkTracker
                        node: Pipewire.defaultAudioSink
                    }

                    Repeater {
                        model: linkTracker.linkGroups

                        VolumeMixerEntry {
                            Layout.fillWidth: true
                            // Get links to the default sinnk
                            required property PwLinkGroup modelData
                            // Consider sources that output to the default sink
                            node: modelData.source
                        }
                    }
                }
            }

            // Placeholder when list is empty
            Item {
                anchors.fill: flickable

                visible: opacity > 0
                opacity: (linkTracker.linkGroups.length === 0) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.menuDecel.duration
                        easing.type: Appearance.animation.menuDecel.type
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 55
                        color: Appearance.m3colors.m3outline
                        text: "brand_awareness"
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("No audio source")
                    }
                }
            }
        }
        // Device selector
        ButtonGroup {
            id: deviceSelectorRowLayout
            Layout.fillWidth: true
            Layout.fillHeight: false
            AudioDeviceSelectorButton {
                Layout.fillWidth: true
                input: false
                onClicked: root.showDeviceSelectorDialog(input)
            }
            AudioDeviceSelectorButton {
                Layout.fillWidth: true
                input: true
                onClicked: root.showDeviceSelectorDialog(input)
            }
        }
    }

    // Device selector dialog
    Item {
        anchors.fill: parent
        z: 9999

        visible: opacity > 0
        opacity: root.showDeviceSelector ? 1 : 0
        Behavior on opacity {
            NumberAnimation { 
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Rectangle { // Scrim
            id: scrimOverlay
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 30
            implicitHeight: dialogColumnLayout.implicitHeight
            
            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: 16

                StyledText {
                    id: dialogTitle
                    Layout.topMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: `Select ${root.deviceSelectorInput ? "input" : "output"} device`
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                Flickable {
                    id: dialogFlickable
                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: Math.min(scrimOverlay.height - dialogMargins * 8 - dialogTitle.height - dialogButtonsRowLayout.height, devicesColumnLayout.implicitHeight)
                    
                    contentHeight: devicesColumnLayout.implicitHeight

                    ColumnLayout {
                        id: devicesColumnLayout
                        anchors.fill: parent
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: ScriptModel {
                                values: Pipewire.nodes.values.filter(node => {
                                    return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio
                                })
                            }

                            // This could and should be refractored, but all data becomes null when passed wtf
                            delegate: StyledRadioButton {
                                id: radioButton
                                required property var modelData
                                Layout.leftMargin: root.dialogMargins
                                Layout.rightMargin: root.dialogMargins
                                Layout.fillWidth: true

                                description: modelData.description
                                checked: modelData.id === Pipewire.defaultAudioSink?.id

                                Connections {
                                    target: root
                                    function onShowDeviceSelectorChanged() {
                                        if(!root.showDeviceSelector) return;
                                        radioButton.checked = (modelData.id === Pipewire.defaultAudioSink?.id)
                                    }
                                }

                                onCheckedChanged: {
                                    if (checked) {
                                        root.selectedDevice = modelData
                                    }
                                }
                            }
                        }
                        Item {
                            implicitHeight: dialogMargins
                        }
                    }
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                RowLayout {
                    id: dialogButtonsRowLayout
                    Layout.bottomMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignRight

                    DialogButton {
                        buttonText: qsTr("Cancel")
                        onClicked: {
                            root.showDeviceSelector = false
                        }
                    }
                    DialogButton {
                        buttonText: qsTr("OK")
                        onClicked: {
                            root.showDeviceSelector = false
                            if (root.selectedDevice) {
                                if (root.deviceSelectorInput) {
                                    Pipewire.preferredDefaultAudioSource = root.selectedDevice
                                } else {
                                    Pipewire.preferredDefaultAudioSink = root.selectedDevice
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.overlay

StyledOverlayWidget {
    id: root

    contentItem: Rectangle {
        id: contentItem
        anchors.centerIn: parent
        color: Appearance.m3colors.m3surfaceContainer
        property real padding: 8
        implicitHeight: contentColumn.implicitHeight + padding * 2
        implicitWidth: 350
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 10

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                BigRecorderButton {
                    materialSymbol: "screenshot_region"
                    name: "Screenshot region"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                    }
                }

                BigRecorderButton {
                    materialSymbol: "photo_camera"
                    name: "Screenshot"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["bash", "-c", "grim - | wl-copy"]);
                    }
                }

                BigRecorderButton {
                    materialSymbol: "screen_record"
                    name: "Record region"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
                    }
                }
                
                BigRecorderButton {
                    materialSymbol: "capture"
                    name: "Record screen"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen", "--sound"]);
                    }
                }
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: false
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                onClicked: {
                    GlobalStates.overlayOpen = false;
                    Qt.openUrlExternally(Directories.videos);
                }
                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "animated_images"
                        iconSize: 20
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Open recordings folder")
                    }
                }
            }
        }
    }

    component BigRecorderButton: RippleButton {
        id: bigButton
        required property string materialSymbol
        required property string name
        implicitHeight: 66
        implicitWidth: 66
        buttonRadius: height / 2

        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bigButton.materialSymbol
            iconSize: 28
        }

        StyledToolTip {
            text: bigButton.name
        }
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    property int wppselectorWidth: 200
    property int wppselectorPadding: 15

    PanelWindow {
        id: wppselectorRoot
        visible: GlobalStates.wppselectorOpen

        function hide() {
            GlobalStates.wppselectorOpen = false
        }

        exclusiveZone: 0
        implicitWidth: 1920
        implicitHeight: 200
        WlrLayershell.namespace: "quickshell:wppselector"
        // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
        // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        HyprlandFocusGrab {
            id: grab
            windows: [ wppselectorRoot ]
            active: GlobalStates.wppselectorOpen
            onCleared: () => {
                if (!active) wppselectorRoot.hide()
            }
        }

        anchors {
            top: true
        }

        Loader {
            id: wppselectorContentLoader
            active: GlobalStates.wppselectorOpen
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                left: parent.left
                topMargin: Appearance.sizes.hyprlandGapsOut
                rightMargin: Appearance.sizes.hyprlandGapsOut
                bottomMargin: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }
            width: wppselectorWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

            focus: GlobalStates.wppselectorOpen
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    wppselectorRoot.hide();
                }
            } 



            sourceComponent: Item {
                implicitHeight: wppselectorBackground.implicitHeight
                implicitWidth: wppselectorBackground.implicitWidth

                Rectangle {
                    id: wppselectorBackground

                    anchors.fill: parent
                    implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                    implicitWidth: wppselectorWidth - Appearance.sizes.hyprlandGapsOut * 2
                    color: Appearance.colors.colLayer0
                    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

                    ColumnLayout {
                        anchors.fill: parent

                        Rectangle {
                            id: flickableBg
                            anchors.margins: 20
                            anchors.fill: parent
                            color: Appearance.colors.colLayer1
                            radius: Appearance.rounding.small
                        }

                        Row {
                            id: optionsRow
                            anchors.fill: parent

                            QuickToggleButton {
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                toggled: false
                                buttonIcon: "autorenew"
                                onClicked: {
                                    Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/images/generate-thumbnails.sh"), Directories.wallpaperPath, "&"])
                                    GlobalStates.wppselectorOpen = !GlobalStates.wppselectorOpen;
                                }
                                StyledToolTip {
                                    content: Translation.tr("Generate Thumbnails")
                                }
                            }
                        }
                        
                        Flickable {
                            id: wallpaperFlickable
                            anchors.fill: flickableBg
                            anchors.margins: wppselectorPadding
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: true
                            clip: true
                            contentWidth: wallpaperRow.implicitWidth
                            contentHeight: height
                            flickableDirection: Flickable.HorizontalFlick


                            Row {
                                id: wallpaperRow
                                spacing: 20
                                anchors.verticalCenter: parent.verticalCenter


                                Repeater {
                                    model: Wallpapers.wallpaperList
                                    delegate: Item {
                                        width: 250
                                        height: wppselectorRoot.implicitHeight - wppselectorPadding

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Appearance.rounding.small
                                            color: Appearance.colors.colLayer2
                                            Layout.fillHeight: true
                                            
                                            Image {
                                                anchors.fill: parent
                                                fillMode: Image.PreserveAspectCrop
                                                source: Directories.wallpaperPath + "/thumbnails/" + modelData
                                                asynchronous: true
                                                cache: true

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        const fullResPath = Directories.wallpaperPath + "/" + modelData
                                                        console.log("Setting wallpaper:", fullResPath)
                                                        GlobalStates.wppselectorOpen = false
                                                        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/colors/switchwall.sh"), fullResPath, "&"])
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "wppselector"

        function toggle(): void {
            GlobalStates.wppselectorOpen = !GlobalStates.wppselectorOpen;
        }

        function close(): void {
            GlobalStates.wppselectorOpen = false;
        }

        function open(): void {
            GlobalStates.wppselectorOpen = true;
        }
    }

    GlobalShortcut {
        name: "wppselectorToggle"
        description: qsTr("Toggles wallpaper selector on press")

        onPressed: {
            GlobalStates.wppselectorOpen = !GlobalStates.wppselectorOpen;
        }
    }
    GlobalShortcut {
        name: "wppselectorOpen"
        description: qsTr("Opens wallpaper selector on press")

        onPressed: {
            GlobalStates.wppselectorOpen = true;
        }
    }
    GlobalShortcut {
        name: "wppselectorClose"
        description: qsTr("Closes wallpaper selector on press")

        onPressed: {
            GlobalStates.wppselectorOpen = false;
        }
    }

}

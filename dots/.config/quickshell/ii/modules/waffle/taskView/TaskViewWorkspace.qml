import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WMouseAreaButton {
    id: root

    required property int workspace

    readonly property real screenWidth: QsWindow.window.width
    readonly property real screenHeight: QsWindow.window.height
    readonly property real screenAspectRatio: screenWidth / screenHeight
    readonly property real screenScale: QsWindow.window.devicePixelRatio
    readonly property real scale: 0.1148148148

    height: ListView.view.height
    implicitWidth: 244 // for now

    onClicked: {
        GlobalStates.overviewOpen = false;
        Hyprland.dispatch(`workspace ${root.workspace}`);
    }

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
            topMargin: 9
            bottomMargin: 8
        }
        spacing: 8

        WText {
            Layout.fillWidth: true
            Layout.fillHeight: false
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            text: Translation.tr("Desktop %1").arg(root.workspace)
        }

        Rectangle {
            id: wsBg
            height: 124
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Looks.colors.bg1Base

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: wsBg.width
                    height: wsBg.height
                    radius: Looks.radius.medium
                }
            }

            StyledImage {
                anchors.fill: parent
                cache: true
                sourceSize: Qt.size(root.screenAspectRatio * 124, 124)
                source: Config.options.background.wallpaperPath
                fillMode: Image.PreserveAspectCrop

                Repeater {
                    model: ScriptModel {
                        values: ToplevelManager.toplevels.values.filter(toplevel => {
                            const address = `0x${toplevel.HyprlandToplevel?.address}`;
                            var win = HyprlandData.windowByAddress[address];
                            const inWorkspace = win?.workspace?.id === root.workspace;
                            return inWorkspace;
                        })
                    }
                    delegate: ScreencopyView {
                        required property var modelData
                        readonly property var hyprlandWindowData: HyprlandData.windowByAddress[`0x${modelData.HyprlandToplevel?.address}`]
                        captureSource: modelData
                        live: true
                        width: hyprlandWindowData?.size[0] * root.scale
                        height: hyprlandWindowData?.size[1] * root.scale
                        x: hyprlandWindowData?.at[0] * root.scale
                        y: hyprlandWindowData?.at[1] * root.scale
                    }
                }
            }
        }
    }
}

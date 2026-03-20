pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import ".."

HBarWidgetWithPopout {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property var activeHyprlandClient: HyprlandData.clientForToplevel(activeWindow)
    readonly property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)
    readonly property bool hasFocusedWindow: (focusingThisMonitor && activeWindow?.activated && biggestWindow) ?? false

    readonly property string primaryText: {
        if (root.hasFocusedWindow)
            return root.activeWindow?.title;
        return (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${root.monitor?.activeWorkspace?.id ?? 1}`;
    }
    readonly property string secondaryText: {
        if (root.hasFocusedWindow && root.activeWindow?.appId != "" && root.activeWindow?.appId != primaryText)
            return root.activeWindow?.appId;
        return Translation.tr("Options")
    }

    property real fontPixelSize: Appearance.font.pixelSize.smaller

    Layout.maximumWidth: implicitWidth
    Layout.fillWidth: true

    popupContentWidth: popupContent.implicitWidth
    popupContentHeight: popupContent.implicitHeight

    HBarWidgetContent {
        id: contentRoot
        Layout.fillWidth: true
        Layout.fillHeight: true
        vertical: root.vertical
        atBottom: root.atBottom
        contentImplicitWidth: winTitleContent.implicitWidth
        contentImplicitHeight: winTitleContent.implicitHeight
        showPopup: false
        onClicked: root.showPopup = !root.showPopup;

        WinTitleContent {
            id: winTitleContent
        }

        WinOptionsPopup {
            id: popupContent
            anchors {
                top: parent.top
                topMargin: root.popupContentOffsetY
                left: parent.left
                leftMargin: root.popupContentOffsetX
            }
            shown: root.showPopup
        }
    }

    component WinTitleContent: BoxLayout {
        anchors.fill: parent
        vertical: root.vertical
        spacing: 4

        Item {
            Layout.leftMargin: 4 * !root.vertical
            Layout.topMargin: 3 * root.vertical
            Layout.bottomMargin: 4 * root.vertical
            Layout.alignment: Qt.AlignCenter
            implicitWidth: appIcon.implicitWidth
            implicitHeight: appIcon.implicitHeight

            AppIcon {
                id: appIcon
                anchors.centerIn: parent
                opacity: 0
                source: Quickshell.iconPath(AppSearch.guessIcon(root.activeWindow?.appId), "image-missing")
                implicitSize: 16
                animated: false
            }
            Circle {
                id: iconMask
                visible: false
                layer.enabled: true
                diameter: appIcon.implicitSize
            }
            Loader {
                anchors.fill: appIcon
                Colorizer {
                    id: renderedIcon
                    implicitWidth: appIcon.implicitWidth
                    implicitHeight: appIcon.implicitHeight
                    colorizationColor: Appearance.colors.colOnLayer0
                    // colorization: Config.options.bar.workspaces.monochromeIcons ? 0.8 : 0.5
                    colorization: 1
                    brightness: 0
                    source: appIcon

                    maskEnabled: true
                    maskSource: iconMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1

                    visible: root.activeWindow
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: !renderedIcon.visible
                text: "overview_key"
                iconSize: 16
            }
        }

        Item {
            visible: !root.vertical
            Layout.rightMargin: 4
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: true
            // No overflow
            Layout.maximumWidth: implicitWidth
            Layout.fillWidth: true
            // Size
            implicitWidth: winText.implicitWidth
            implicitHeight: winText.implicitHeight
            
            FlyFadeEnterChoreographable {
                anchors.fill: parent
                progress: contentRoot.containsMouse ? 0 : 1
                reverseDirection: true
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                VisuallyCenteredStyledText {
                    id: winText
                    height: parent.height
                    width: parent.width
                    elide: Text.ElideRight
                    // Styles & text
                    font.pixelSize: root.fontPixelSize
                    text: root.primaryText
                }
            }
            FlyFadeEnterChoreographable {
                anchors.fill: parent
                progress: contentRoot.containsMouse ? 1 : 0
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                VisuallyCenteredStyledText {
                    height: parent.height
                    width: parent.width
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    // Styles & text
                    font.pixelSize: root.fontPixelSize
                    text: root.secondaryText
                }
            }
        }
    }

    component WinOptionsPopup: ChoreographerLoader {
        sourceComponent: ChoreographerGridLayout {
            id: popupRoot

            columns: 3
            rowSpacing: 8
            columnSpacing: 6

            FlyFadeEnterChoreographable {
                Layout.fillWidth: true
                Layout.columnSpan: 3
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.hasFocusedWindow ? Translation.tr("Window options") : Translation.tr("Launch")
                    // font.pixelSize: Appearance.font.pixelSize.title
                }
            }

            FlyFadeEnterChoreographable {
                visible: !root.hasFocusedWindow
                PopupLabeledIconButton {
                    materialSymbol: "terminal"
                    text: Translation.tr("Terminal")
                    onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.terminal]);
                }
            }

            FlyFadeEnterChoreographable {
                visible: !root.hasFocusedWindow
                PopupLabeledIconButton {
                    materialSymbol: "files"
                    text: Translation.tr("Files")
                    onClicked: Qt.openUrlExternally(Directories.home);
                }
            }

            FlyFadeEnterChoreographable {
                visible: !root.hasFocusedWindow
                PopupLabeledIconButton {
                    materialSymbol: "language"
                    text: Translation.tr("Browser")
                    // Kinda hacky. Works with Google and DDG at least
                    onClicked: Qt.openUrlExternally(Config.options.search.engineBaseUrl);
                }
            }

            FlyFadeEnterChoreographable {
                visible: root.hasFocusedWindow
                PopupLabeledIconButton {
                    materialSymbol: "content_copy"
                    text: Translation.tr("Address")
                    onClicked: Quickshell.clipboardText = root.activeHyprlandClient.address
                }
            }

            FlyFadeEnterChoreographable {
                visible: root.hasFocusedWindow
                PopupLabeledIconButton {
                    property bool toFloat: !(root.activeHyprlandClient?.floating ?? false)
                    materialSymbol: toFloat ? "picture_in_picture_center" : "side_navigation"
                    text: toFloat ? Translation.tr("Float") : Translation.tr("Tile")
                    onClicked: {
                        Hyprland.dispatch(`togglefloating address:${root.activeHyprlandClient.address}`)
                        HyprlandData.updateWindowList()
                    }
                }
            }

            FlyFadeEnterChoreographable {
                visible: root.hasFocusedWindow
                PopupLabeledIconButton {
                    materialSymbol: "warning"
                    text: Translation.tr("Kill")
                    colBackground: Appearance.colors.colError
                    colForeground: Appearance.colors.colOnError
                    onClicked: {
                        Hyprland.dispatch(`killwindow address:${root.activeHyprlandClient.address}`)
                        HyprlandData.updateWindowList()
                    }
                }
            }
        }
    }

    component PopupLabeledIconButton: Column {
        id: licobtn
        property string materialSymbol: "circle"
        property string text: "Label"
        property alias colBackground: btn.colBackground
        property alias colForeground: btn.colForeground
        spacing: 4

        signal clicked()
        onClicked: root.showPopup = false

        StyledIconButton {
            id: btn
            implicitWidth: 70
            implicitHeight: 50
            text: licobtn.materialSymbol
            iconSize: 24
            colBackground: Appearance.colors.colLayer4
            colForeground: Appearance.colors.colOnLayer4
            onClicked: licobtn.clicked()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: licobtn.text
        }
    }
}

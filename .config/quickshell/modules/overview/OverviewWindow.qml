import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import "./icons.js" as Icons

Rectangle { // Window
    id: root

    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real initX: Math.max((windowData?.at[0] - monitorData?.reserved[0]) * root.scale, 0) + xOffset
    property real initY: Math.max((windowData?.at[1] - monitorData?.reserved[1]) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    
    property var targetWindowWidth: windowData?.size[0] * scale
    property var targetWindowHeight: windowData?.size[1] * scale
    property bool hovered: false
    property bool pressed: false

    property var iconToWindowRatio: 0.35
    property var xwaylandIndicatorToIconRatio: 0.35
    property var iconToWindowRatioCompact: 0.6
    property var iconPath: Quickshell.iconPath(Icons.noKnowledgeIconGuess(windowData?.class))
    property bool compactMode: Appearance.font.pixelSize.smaller * 4 > targetWindowHeight || Appearance.font.pixelSize.smaller * 4 > targetWindowWidth
    
    x: initX
    y: initY
    width: Math.min(windowData?.size[0] * root.scale, (restrictToWorkspace ? windowData?.size[0] : availableWorkspaceWidth - x + xOffset))
    height: Math.min(windowData?.size[1] * root.scale, (restrictToWorkspace ? windowData?.size[1] : availableWorkspaceHeight - y + yOffset))

    radius: Appearance.rounding.windowRounding * root.scale
    color: pressed ? Appearance.colors.colLayer2Active : hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
    border.color : Appearance.transparentize(Appearance.m3colors.m3outline, 0.9)
    border.pixelAligned : false
    border.width : 1

    Behavior on x {
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }

    Process {
        id: closeOverview
        command: ["bash", "-c", "qs ipc call overview close &"] // Somehow has to by async to work?
    }

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.font.pixelSize.smaller * 0.5

        IconImage {
            id: windowIcon
            Layout.alignment: Qt.AlignHCenter
            source: root.iconPath
            implicitSize: Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)

            Behavior on implicitSize {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            IconImage {
                id: xwaylandIndicator
                visible: (ConfigOptions.overview.showXwaylandIndicator && windowData?.xwayland) ?? false
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                source: Quickshell.iconPath("xorg")
                implicitSize: windowIcon.implicitSize * xwaylandIndicatorToIconRatio
            }
        }

        StyledText {
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            visible: !compactMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            elide: Text.ElideRight
            // wrapMode: Text.Wrap
            text: windowData?.title ?? ""
        }
    }
}
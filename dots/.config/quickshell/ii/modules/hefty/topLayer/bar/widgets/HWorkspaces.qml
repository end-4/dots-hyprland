pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    WorkspaceModel {
        id: wsModel
        monitor: root.monitor
    }

    property bool vertical: Config.options.bar.vertical
    property bool superPressAndHeld: false // Relevant modifications at bottom of file

    property real workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - 1) % wsModel.shownCount
    property real specialTextSize: workspaceButtonWidth * 0.5

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : occupiedIndicators.implicitWidth
    implicitHeight: vertical ? occupiedIndicators.implicitHeight : Appearance.sizes.barHeight

    property real specialBlur: wsModel.specialWorkspaceActive ? 1 : 0
    Behavior on specialBlur {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Item {
        id: regularWorkspaces
        anchors.fill: parent

        scale: 1 - 0.08 * root.specialBlur
        layer.smooth: true
        layer.enabled: root.specialBlur > 0
        layer.effect: MultiEffect {
            brightness: -0.1 * root.specialBlur
            blurEnabled: true
            blur: root.specialBlur
            blurMax: 32
        }

        /////////////////// Occupied indicators ///////////////////
        StyledRectangle {
            id: occupiedIndicatorsBg
            anchors.fill: parent
            contentLayer: StyledRectangle.ContentLayer.Group
            color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
            visible: false
        }

        WorkspaceLayout {
            id: occupiedIndicators
            anchors.centerIn: parent

            layer.enabled: true
            visible: false

            Repeater {
                model: wsModel.shownCount
                delegate: Item {
                    id: wsBg
                    required property int index
                    readonly property int wsId: wsModel.getWorkspaceIdAt(index)
                    property bool currentOccupied: wsModel.occupied[index] && wsId != wsModel.fakeWorkspace
                    property bool previousOccupied: index > 0 && wsModel.occupied[index - 1] && (wsId - 1) != wsModel.fakeWorkspace
                    property bool nextOccupied: index < wsModel.shownCount - 1 && wsModel.occupied[index + 1] && (wsId + 1) != wsModel.fakeWorkspace
                    implicitWidth: root.workspaceButtonWidth
                    implicitHeight: root.workspaceButtonWidth

                    // The idea: over-stretch to occupied sides, animate this for a smooth transition.
                    //           masking already prevents weird overlaps
                    Pill {
                        property real undirectionalWidth: root.workspaceButtonWidth * wsBg.currentOccupied
                        property real undirectionalLength: root.workspaceButtonWidth * (1 + 0.5 * wsBg.previousOccupied + 0.5 * wsBg.nextOccupied) * currentOccupied
                        property real undirectionalOffset: (!wsBg.currentOccupied ? 0.5 : -0.5 * wsBg.previousOccupied) * root.workspaceButtonWidth
                        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        x: root.vertical ? 0 : undirectionalOffset
                        y: root.vertical ? undirectionalOffset : 0
                        implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
                        implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

                        Behavior on undirectionalWidth {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalLength {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalOffset {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        MaskMultiEffect {
            id: occupiedIndicatorsMultiEffect
            z: 1
            anchors.centerIn: parent
            implicitWidth: occupiedIndicators.implicitWidth
            implicitHeight: occupiedIndicators.implicitHeight
            source: occupiedIndicatorsBg
            maskSource: occupiedIndicators
        }

        /////////////////// Active indicator ///////////////////
        TrailingIndicator {
            id: activeIndicator
            anchors.fill: parent
            z: 2

            index: root.workspaceIndexInGroup
        }

        /////////////////// Hover ///////////////////
        MouseArea {
            id: interactionMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            property int hoverIndex: {
                const position = root.vertical ? mouseY : mouseX;
                return Math.floor(position / root.workspaceButtonWidth);
            }

            onPressed: Hyprland.dispatch(`workspace ${wsModel.getWorkspaceIdAt(hoverIndex)}`)
            onWheel: (event) => {
                if (event.angleDelta.y < 0)
                    Hyprland.dispatch(`workspace r+1`);
                else if (event.angleDelta.y > 0)
                    Hyprland.dispatch(`workspace r-1`);
            }

            TrailingIndicator {
                id: interactionIndicator
                index: interactionMouseArea.containsMouse ? interactionMouseArea.hoverIndex : root.workspaceIndexInGroup
                color: "transparent"
                StateOverlay {
                    id: hoverOverlay
                    anchors.fill: interactionIndicator.indicatorRectangle
                    radius: root.activeWorkspaceSize / 2
                    hover: interactionMouseArea.containsMouse
                    press: interactionMouseArea.containsPress
                    contentColor: Appearance.colors.colPrimary
                }
            }
        }

        /////////////////// Numbers ///////////////////
        WorkspaceLayout {
            id: numbersGrid
            z: 4
            layer.enabled: true // For the masking

            Repeater {
                model: wsModel.shownCount
                delegate: NumberWorkspaceItem {}
            }
        }
        Colorizer {
            z: 5
            anchors.fill: numbersGrid
            colorizationColor: Appearance.colors.colOnPrimary
            sourceColor: Appearance.colors.colOnSecondaryContainer

            source: activeIndicator
            maskEnabled: true
            maskSource: numbersGrid

            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        /////////////////// App icons ///////////////////
        WorkspaceLayout {
            id: appsGrid
            z: 6

            Repeater {
                model: wsModel.shownCount
                delegate: WorkspaceItem {
                    id: wsApp
                    property var biggestWindow: wsModel.biggestWindow[index]
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    AppIcon {
                        id: appIcon
                        property real cornerMargin: (!root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons) ? 
                            (root.workspaceButtonWidth - root.workspaceIconSize) / 2 : root.workspaceIconMarginShrinked
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                            bottomMargin: (parent.implicitHeight - root.workspaceButtonWidth) / 2 + cornerMargin
                            rightMargin: (parent.implicitWidth - root.workspaceButtonWidth) / 2 + cornerMargin
                        }

                        animated: !wsApp.biggestWindow // Prevent the "image-missing" icon
                        visible: false // Prevent dupe: the colorizer already copies the icon

                        source: wsApp.mainAppIconSource
                        implicitSize: NumberUtils.roundToEven((!root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons) ? root.workspaceIconSize : root.workspaceIconSizeShrinked)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on cornerMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on implicitSize {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    Circle {
                        id: iconMask
                        visible: false
                        layer.enabled: true
                        diameter: appIcon.implicitSize
                    }

                    Colorizer {
                        anchors.fill: appIcon
                        implicitWidth: appIcon.implicitWidth
                        implicitHeight: appIcon.implicitHeight
                        colorizationColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                        colorization: Config.options.bar.workspaces.monochromeIcons ? 0.8 : 0.5
                        brightness: 0
                        source: appIcon

                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (wsApp.biggestWindow && !root.superPressAndHeld && Config.options?.bar.workspaces.showAppIcons) ? 
                            1 : wsApp.biggestWindow ? root.workspaceIconOpacityShrinked : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        maskEnabled: true
                        maskSource: iconMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }
                }
            }
        }
    }

    FadeLoader {
        anchors.centerIn: parent
        shown: wsModel.specialWorkspaceActive

        scale: 0.8 + 0.2 * root.specialBlur
        // layer.enabled: true
        // layer.smooth: true

        Pill {
            anchors.centerIn: parent
            property real undirectionalWidth: root.activeWorkspaceSize
            property real undirectionalLength: {
                const base = root.workspaceButtonWidth * Math.min(1.35, wsModel.shownCount) // Who tf only configures only 2 workspaces shown anyway?
                if (root.vertical) return base;
                return specialWsText.implicitWidth + undirectionalWidth
            }
            color: Appearance.colors.colPrimary

            implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
            implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

            StyledText {
                id: specialWsText
                anchors.centerIn: parent
                text: (!root.vertical ? wsModel.specialWorkspaceName : "S")
                color: Appearance.colors.colOnPrimary
                font.pixelSize: root.specialTextSize
            }

            Behavior on undirectionalLength {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }
    }

    /////////////////// Components ///////////////////
    component WorkspaceLayout: Grid {
        anchors {
            top: !vertical ? parent.top : undefined
            bottom: !vertical ? parent.bottom : undefined
            left: vertical ? parent.left : undefined
            right: vertical ? parent.right : undefined
        }

        rowSpacing: 0
        columnSpacing: 0
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
    }

    component WorkspaceItem: Item {
        required property int index
        readonly property int wsId: wsModel.getWorkspaceIdAt(index)
        implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : root.workspaceButtonWidth
        implicitHeight: root.vertical ? root.workspaceButtonWidth : Appearance.sizes.barHeight
    }

    component NumberWorkspaceItem: WorkspaceItem {
        id: wsNum
        property bool hasBiggestWindow: !!wsModel.biggestWindow[index]
        property color contentColor: wsModel.occupied[wsNum.index] ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1Inactive

        FadeLoader {
            shown: !(Config.options?.bar.workspaces.alwaysShowNumbers
                || root.superPressAndHeld
                || (Config.options?.bar.workspaces.showAppIcons && wsNum.hasBiggestWindow)
            )
            anchors.centerIn: parent
            Circle {
                anchors.centerIn: parent
                diameter: root.workspaceButtonWidth * 0.18
                color: wsNum.contentColor
            }
        }
        FadeLoader {
            shown: root.superPressAndHeld
                || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !wsNum.hasBiggestWindow || root.showNumbers))
                || (root.superPressAndHeld && !Config.options?.bar.workspaces.showAppIcons)
            )
            anchors.centerIn: parent
            StyledText {
                anchors.centerIn: parent
                font {
                    pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                    family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                }
                color: wsNum.contentColor
                text: Config.options?.bar.workspaces.numberMap[wsNum.wsId - 1] || wsNum.wsId
            }
        }
    }

    component TrailingIndicator: Item {
        id: trailingIndicator
        anchors.fill: parent
        required property int index
        property alias indicatorRectangle: indicatorRect
        property alias color: indicatorRect.color

        property var indexPair: AnimatedTabIndexPair {
            id: idxPair
            index: trailingIndicator.index
        }

        StyledRectangle {
            id: indicatorRect
            anchors {
                verticalCenter: vertical ? undefined : parent.verticalCenter
                horizontalCenter: vertical ? parent.horizontalCenter : undefined
            }

            property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceMargin
            property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceSize
            property real indicatorThickness: root.activeWorkspaceSize

            contentLayer: StyledRectangle.ContentLayer.Group
            radius: indicatorThickness / 2
            color: Appearance.colors.colPrimary

            x: root.vertical ? null : indicatorPosition
            y: root.vertical ? indicatorPosition : null
            implicitWidth: root.vertical ? indicatorThickness : indicatorLength
            implicitHeight: root.vertical ? indicatorLength : indicatorThickness
        }
    }

    /////////////////// Super key press handling ///////////////////
    Timer {
        id: superPressAndHeldTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.superPressAndHeld = true;
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable)
                return;
            if (GlobalStates.superDown)
                superPressAndHeldTimer.restart();
            else {
                superPressAndHeldTimer.stop();
                root.superPressAndHeld = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            superPressAndHeldTimer.stop();
        }
    }
}

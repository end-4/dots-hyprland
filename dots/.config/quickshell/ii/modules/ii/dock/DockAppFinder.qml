pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    property var dockWindow
    property bool showing: false
    property real gapFromDock: 12
    property string searchText: ""
    property string _pendingSearchText: ""

    // Debounce search input so we don't run fuzzy search on every keystroke
    Timer {
        id: searchDebounce
        interval: 150
        repeat: false
        onTriggered: {
            root.searchText = root._pendingSearchText
        }
    }
    readonly property real dockHeight: root.dockWindow?.implicitHeight ?? 70

    screen: root.dockWindow?.screen
    color: "transparent"
    visible: root.showing || contentWrapper.opacity > 0
    exclusionMode: ExclusionMode.Ignore

    // Position: bottom of screen, above the dock
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: root.dockHeight + root.gapFromDock
    }

    WlrLayershell.namespace: "quickshell:appfinder"
    WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    implicitWidth: contentWrapper.implicitWidth
    implicitHeight: contentWrapper.implicitHeight

    // Clean rounded corners (same pattern as SidebarLeft)
    mask: Region { item: bg }

    // ── Dismiss (same pattern as SidebarRight) ──
    onVisibleChanged: {
        if (visible)
            GlobalFocusGrab.addDismissable(root)
        else
            GlobalFocusGrab.removeDismissable(root)
    }
    Connections {
        target: GlobalFocusGrab
        function onDismissed() { root.showing = false }
    }

    // ── Animation: slide up from below ──
    property real animSlide: showing ? 0 : contentWrapper.implicitHeight
    property real animOpacity: showing ? 1.0 : 0.0

    Behavior on animSlide {
        NumberAnimation {
            duration: showing ? 350 : 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: showing
                ? Appearance.animationCurves.emphasizedDecel
                : Appearance.animationCurves.emphasizedAccel
        }
    }
    Behavior on animOpacity {
        NumberAnimation {
            duration: showing ? 250 : 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: showing
                ? Appearance.animationCurves.standardDecel
                : Appearance.animationCurves.standardAccel
        }
    }

    onShowingChanged: {
        if (!showing) {
            searchText = ""
            _pendingSearchText = ""
            input.text = ""
        }
    }

    // ── Content ──
    Item {
        id: contentWrapper
        anchors.horizontalCenter: parent.horizontalCenter
        // y animated for slide-up; NO top anchor to avoid conflict
        y: root.animSlide
        opacity: root.animOpacity

        readonly property real pad: 12
        readonly property real gap: 8
        readonly property real sbHeight: 48
        readonly property int panelWidth: Config.options?.dock.appFinder.width ?? 640
        readonly property int panelHeight: Config.options?.dock.appFinder.height ?? 560

        implicitWidth: panelWidth
        implicitHeight: sbHeight + panelHeight + pad * 2 + gap

        StyledRectangularShadow { target: bg }

        Rectangle {
            id: bg
            anchors.fill: parent
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                anchors { fill: parent; margins: contentWrapper.pad }
                spacing: contentWrapper.gap

                // ── Search bar ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: contentWrapper.sbHeight
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    radius: Appearance.rounding.full

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 6

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "search"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: input.implicitHeight

                            TextInput {
                                id: input
                                anchors.fill: parent
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                                activeFocusOnPress: true
                                focus: root.showing
                                onTextChanged: {
                                    root._pendingSearchText = text
                                    searchDebounce.restart()
                                }
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.showing = false
                                        event.accepted = true
                                    }
                                }
                            }

                            StyledText {
                                anchors.fill: parent
                                text: Translation.tr("Search apps...")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                                visible: input.text === "" && !input.activeFocus
                            }
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 28; implicitHeight: 28
                            visible: input.text !== ""
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                            onClicked: {
                                input.text = ""
                                root._pendingSearchText = ""
                                searchDebounce.restart()
                            }
                        }
                    }
                }

                // Grid area with fixed configured height; scrolls internally
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentWrapper.panelHeight

                    Loader {
                        id: appGridLoader
                        active: root.showing
                        anchors.fill: parent
                        sourceComponent: appGridComponent
                    }

                    Component {
                        id: appGridComponent
                        DockAppFinderGrid {
                            anchors.fill: parent
                            searchText: root.searchText
                        }
                    }
                }

            }
        }
    }
}



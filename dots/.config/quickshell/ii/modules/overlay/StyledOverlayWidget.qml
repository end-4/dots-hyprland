pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas

/*
 * To make an overlay widget:
 * 1. Create a modules/overlay/<yourWidget>/<YourWidget>.qml, using this as the base class and declare your widget content as contentItem
 * 2. Add an entry to OverlayContext.availableWidgets with identifier=<yourWidgetIdentifier>
 * 3. Add an entry in Persistent.states.overlay.<yourWidgetIdentifier> with x, y, pinned, clickthrough properties set to reasonable defaults
 * 4. Add an entry in OverlayWidgetDelegateChooser with roleValue=<yourWidgetIdentifier> and Declare your widget in there
 * Use existing entries as reference.
 */
AbstractOverlayWidget {
    id: root

    required property Item contentItem

    required property var modelData
    readonly property string identifier: modelData.identifier
    readonly property string materialSymbol: modelData.materialSymbol ?? "widgets"
    property string title: identifier.replace(/([A-Z])/g, " $1").replace(/^./, function(str){ return str.toUpperCase(); })
    property var persistentStateEntry: Persistent.states.overlay[identifier]
    property real radius: Appearance.rounding.windowRounding
    property real minWidth: 250

    draggable: GlobalStates.overlayOpen
    x: Math.round(persistentStateEntry.x) // Round or it'll be blurry
    y: Math.round(persistentStateEntry.y) // Round or it'll be blurry
    pinned: persistentStateEntry.pinned
    clickthrough: persistentStateEntry.clickthrough
    drag {
        minimumX: 0
        minimumY: 0
        maximumX: root.parent.width - root.width
        maximumY: root.parent.height - root.height
    }

    // Guarded states & registration funcs
    property bool open: Persistent.states.overlay.open
    property bool actuallyPinned: pinned && open
    property bool actuallyClickable: !clickthrough && actuallyPinned && open
    onActuallyPinnedChanged: reportPinnedState();
    onActuallyClickableChanged: reportClickableState();
    function reportPinnedState() {
        OverlayContext.pin(identifier, actuallyPinned);
    }
    function reportClickableState() {
        OverlayContext.registerClickableWidget(contentItem, actuallyClickable);
    }

    // Self-registeration with OverlayContext
    Component.onCompleted: {
        reportPinnedState();
        reportClickableState();
    }

    // Hooks
    onReleased: savePosition();

    function close() {
        Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== root.identifier);
    }

    function togglePinned() {
        persistentStateEntry.pinned = !persistentStateEntry.pinned;
    }

    function toggleClickthrough() {
        persistentStateEntry.clickthrough = !persistentStateEntry.clickthrough;
    }

    function savePosition(xPos = root.x, yPos = root.y) {
        persistentStateEntry.x = xPos;
        persistentStateEntry.y = yPos;
    }

    function center() {
        const targetX = (root.parent.width - contentColumn.width) / 2
        const targetY = (root.parent.height - contentItem.height) / 2 - titleBar.implicitHeight
        root.x = targetX
        root.y = targetY
        root.savePosition(targetX, targetY)
    }

    visible: GlobalStates.overlayOpen || actuallyPinned
    implicitWidth: Math.max(contentColumn.implicitWidth, minWidth)
    implicitHeight: contentColumn.implicitHeight

    Rectangle {
        id: border
        anchors.fill: parent
        color: "transparent"
        radius: root.radius
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, GlobalStates.overlayOpen ? 0 : 1)
        border.width: 1

        layer.enabled: GlobalStates.overlayOpen
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: border.width
                height: border.height
                radius: root.radius
            }
        }

        Column {
            id: contentColumn
            z: -1
            anchors.fill: parent

            // Title bar
            Rectangle {
                id: titleBar
                opacity: GlobalStates.overlayOpen ? 1 : 0
                anchors {
                    left: parent.left
                    right: parent.right
                }
                property real padding: 2
                implicitWidth: titleBarRow.implicitWidth + padding * 2
                implicitHeight: titleBarRow.implicitHeight + padding * 2
                color: Appearance.m3colors.m3surfaceContainer
                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                
                RowLayout {
                    id: titleBarRow
                    anchors {
                        fill: parent
                        margins: titleBar.padding
                        leftMargin: titleBar.padding + 8
                    }
                    spacing: 0

                    MaterialSymbol {
                        text: root.materialSymbol
                        iconSize: 20
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 4
                    }
                    
                    StyledText {
                        text: root.title
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    TitlebarButton {
                        materialSymbol: "recenter"
                        onClicked: root.center()
                        StyledToolTip {
                            text: "Center"
                        }
                    }

                    TitlebarButton {
                        materialSymbol: "mouse"
                        toggled: !root.clickthrough
                        onClicked: root.toggleClickthrough()
                        StyledToolTip {
                            text: "Clickable when pinned"
                        }
                    }

                    TitlebarButton {
                        materialSymbol: "keep"
                        toggled: root.pinned
                        onClicked: root.togglePinned()
                        StyledToolTip {
                            text: "Pin"
                        }
                    }

                    TitlebarButton {
                        materialSymbol: "close"
                        onClicked: root.close()
                        StyledToolTip {
                            text: "Close"
                        }
                    }
                }
            }

            // Content
            Item {
                id: contentContainer
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: root.contentItem.implicitWidth
                implicitHeight: root.contentItem.implicitHeight
                children: [root.contentItem]
            }
        }
    }


    component TitlebarButton: RippleButton {
        id: titlebarButton
        required property string materialSymbol
        buttonRadius: height / 2
        implicitHeight: contentItem.implicitHeight
        implicitWidth: implicitHeight
        padding: 0

        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        contentItem: Item {
            anchors.centerIn: parent
            implicitWidth: 30
            implicitHeight: 30

            MaterialSymbol {
                id: iconWidget
                anchors.centerIn: parent
                iconSize: 20
                text: titlebarButton.materialSymbol
                fill: titlebarButton.toggled
                color: titlebarButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface
            }
        }
    }
}

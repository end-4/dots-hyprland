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
 * 3. Add an entry in Persistent.states.overlay.<yourWidgetIdentifier> with x, y, width, height, pinned, clickthrough properties set to reasonable defaults
 * 4. Add an entry in OverlayWidgetDelegateChooser with roleValue=<yourWidgetIdentifier> and Declare your widget in there
 * Use existing entries as reference.
 */
AbstractOverlayWidget {
    id: root

    // To be defined by subclasses
    required property Item contentItem
    property bool fancyBorders: true
    property bool showCenterButton: false
    property bool showClickabilityButton: true

    // Defaults n stuff
    required property var modelData
    readonly property string identifier: modelData.identifier
    readonly property string materialSymbol: modelData.materialSymbol ?? "widgets"
    property string title: identifier.replace(/([A-Z])/g, " $1").replace(/^./, function(str){ return str.toUpperCase(); })
    property var persistentStateEntry: Persistent.states.overlay[identifier]
    property real radius: Appearance.rounding.windowRounding
    property real minimumWidth: contentItem.implicitWidth
    property real minimumHeight: contentItem.implicitHeight
    property real resizeMargin: 8
    property real padding: 6
    property real contentRadius: radius - padding

    // Resizing
    function getXResizeDirection(x) {
        return (x < root.resizeMargin) ? -1 : (x > root.width - root.resizeMargin) ? 1 : 0
    }
    function getYResizeDirection(y) {
        return (y < root.resizeMargin) ? -1 : (y > root.height - root.resizeMargin) ? 1 : 0
    }
    hoverEnabled: true
    property bool resizable: true
    property bool resizing: false
    property int resizeXDirection: getXResizeDirection(mouseX)
    property int resizeYDirection: getYResizeDirection(mouseY)
    draggable: GlobalStates.overlayOpen
    drag.target: undefined
    animateXPos: !dragHandler.active
    animateYPos: !dragHandler.active
    z: dragHandler.active ? 2 : 1
    cursorShape: {
        if (dragHandler.active) return root.resizing ? cursorShape : Qt.ArrowCursor;
        if (resizeMargin < mouseX && mouseX < width - resizeMargin &&
            resizeMargin < mouseY && mouseY < height - resizeMargin) {
            return Qt.ArrowCursor;
        } else {
            if (!root.resizable) return Qt.ArrowCursor;
            const dragIsLeft = mouseX < width / 2
            const dragIsTop = mouseY < height / 2
            if ((dragIsLeft && dragIsTop) || (!dragIsLeft && !dragIsTop)) {
                return Qt.SizeFDiagCursor
            } else {
                return Qt.SizeBDiagCursor
            }
        }
    }

    // Positioning & sizing
    x: Math.round(persistentStateEntry.x) // Round or it'll be blurry
    y: Math.round(persistentStateEntry.y) // Round or it'll be blurry
    pinned: persistentStateEntry.pinned
    clickthrough: persistentStateEntry.clickthrough
    drag {
        minimumX: 0
        minimumY: 0
        maximumX: root.parent?.width - root.width
        maximumY: root.parent?.height - root.height
    }
    opacity: (GlobalStates.overlayOpen || !clickthrough) ? 1.0 : Config.options.overlay.clickthroughOpacity

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
    onPressed: (event) => {
        // We're only interested in handling resize here
        // Early returns
        if (!root.resizable) return;
        if (root.resizeMargin < event.x && event.x < root.width - root.resizeMargin &&
            root.resizeMargin < event.y && event.y < root.height - root.resizeMargin) {
            return;
        }
        // Resizing setup
        root.resizing = true;
        root.resizeXDirection = getXResizeDirection(event.x);
        root.resizeYDirection = getYResizeDirection(event.y);
        if (root.resizeYDirection !== 0 && root.resizeXDirection === 0) {
            root.resizeXDirection = event.x < root.width / 2 ? -1 : 1;
        } else if (root.resizeXDirection !== 0 && root.resizeYDirection === 0) {
            root.resizeYDirection = event.y < root.height / 2 ? -1 : 1;
        }
    }
    onPositionChanged: (event) => {
        if (!resizing) return;
        contentContainer.implicitWidth = Math.max(root.persistentStateEntry.width + dragHandler.xAxis.activeValue * root.resizeXDirection, root.minimumWidth);
        contentContainer.implicitHeight = Math.max(root.persistentStateEntry.height + dragHandler.yAxis.activeValue * root.resizeYDirection, root.minimumHeight);
        const negativeXDrag = root.resizeXDirection === -1;
        const negativeYDrag = root.resizeYDirection === -1;
        const wantedX = root.persistentStateEntry.x + (negativeXDrag ? dragHandler.xAxis.activeValue : 0)
        const wantedY = root.persistentStateEntry.y + (negativeYDrag ? dragHandler.yAxis.activeValue : 0)
        const negativeXDragLimit = root.persistentStateEntry.x + root.persistentStateEntry.width - contentContainer.implicitWidth;
        const negativeYDragLimit = root.persistentStateEntry.y + root.persistentStateEntry.height - contentContainer.implicitHeight;
        root.x = negativeXDrag ? Math.min(wantedX, negativeXDragLimit) : wantedX;
        root.y = negativeYDrag ? Math.min(wantedY, negativeYDragLimit) : wantedY;
    }
    DragHandler {
        id: dragHandler
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        target: (root.draggable && !root.resizing) ? root : null
        onActiveChanged: { // Handle drag release
            if (!active) {
                root.resizing = false;
                root.savePosition();
            }
        }
        xAxis.minimum: 0
        xAxis.maximum: root.parent?.width - root.width
        yAxis.minimum: 0
        yAxis.maximum: root.parent?.height - root.height
    }

    function close() {
        Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== root.identifier);
    }

    function togglePinned() {
        persistentStateEntry.pinned = !persistentStateEntry.pinned;
    }

    function toggleClickthrough() {
        persistentStateEntry.clickthrough = !persistentStateEntry.clickthrough;
    }

    function savePosition(xPos = root.x, yPos = root.y, width = contentContainer.implicitWidth, height = contentContainer.implicitHeight) {
        persistentStateEntry.x = Math.round(xPos);
        persistentStateEntry.y = Math.round(yPos);
        persistentStateEntry.width = Math.round(width);
        persistentStateEntry.height = Math.round(height);
    }

    function center() {
        const targetX = (root.parent.width - contentColumn.width) / 2 - root.resizeMargin
        const targetY = (root.parent.height - contentContainer.height) / 2 - titleBar.implicitHeight + border.border.width - root.resizeMargin
        root.x = targetX
        root.y = targetY
        root.savePosition(targetX, targetY)
    }

    visible: GlobalStates.overlayOpen || actuallyPinned
    implicitWidth: contentColumn.implicitWidth + resizeMargin * 2
    implicitHeight: contentColumn.implicitHeight + resizeMargin * 2

    Rectangle {
        id: border
        anchors {
            fill: parent
            margins: root.resizeMargin
        }
        color: ColorUtils.transparentize(Appearance.colors.colLayer1, (root.fancyBorders && GlobalStates.overlayOpen) ? 0 : 1)
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

        ColumnLayout {
            id: contentColumn
            z: root.fancyBorders ? 0 : -1
            anchors.fill: parent
            spacing: 0

            // Title bar
            Rectangle {
                id: titleBar
                opacity: GlobalStates.overlayOpen ? 1 : 0
                Layout.fillWidth: true
                implicitWidth: titleBarRow.implicitWidth + root.padding * 2
                implicitHeight: titleBarRow.implicitHeight + root.padding * 2
                color: root.fancyBorders ? "transparent" : Appearance.colors.colLayer1
                // border.color: Appearance.colors.colOutlineVariant
                // border.width: 1
                
                RowLayout {
                    id: titleBarRow
                    anchors {
                        fill: parent
                        margins: root.padding
                    }
                    spacing: 2

                    MaterialSymbol {
                        text: root.materialSymbol
                        Layout.leftMargin: 6
                        iconSize: 20
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 4
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: root.title
                        elide: Text.ElideRight
                    }

                    TitlebarButton {
                        visible: root.showCenterButton
                        materialSymbol: "recenter"
                        onClicked: root.center()
                        StyledToolTip {
                            text: "Center"
                        }
                    }

                    TitlebarButton {
                        visible: (root.pinned && root.showClickabilityButton)
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: root.fancyBorders ? root.padding : 0
                Layout.topMargin: -border.border.width // Border of a rectangle is drawn inside its bounds, so we do this to make the gap not too big
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                implicitWidth: Math.max(root.persistentStateEntry.width, root.minimumWidth)
                implicitHeight: Math.max(root.persistentStateEntry.height, root.minimumHeight)
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

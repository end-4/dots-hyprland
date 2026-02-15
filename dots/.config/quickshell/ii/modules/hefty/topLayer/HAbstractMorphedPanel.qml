import QtQuick
import Quickshell
import qs.services as S

/**
 * Abstract morphed panel to be used in TopLayerPanel.
 * Screen width and height are to be supplied when declared in the top layer panel
 * Others are to be declared by panels deriving from this
 *
 * To make sure morph movements don't look weird:
 *   - Follow the convention of having points start from bottom-middle and go clockwise
 *   - Make sure the number of points is "balanced" in all directions
 *     - Tip: Sometimes symmetry is not enough. Try to have more intermediate points if ones you have are too spaced out and act funny.
 */
Item {
    id: root

    // To be fed
    property int screenWidth: QsWindow.window.width
    property int screenHeight: QsWindow.window.height

    // Signals & loading
    signal requestFocus()
    signal dismissed()
    signal focusGrabDismissed()
    property bool load: true
    property bool shown: true

    // Some info
    property int reservedTop: 0
    property int reservedBottom: 0
    property int reservedLeft: 0
    property int reservedRight: 0

    // Main stuff
    property var backgroundPolygon
    property list<Item> baseMaskItems: [root]
    property list<Item> attachedMaskItems: []
    property list<Item> maskItems: [...baseMaskItems, ...attachedMaskItems]
    property Region maskRegion: Region {
        regions: root.maskItems.map(item => regionComp.createObject(this, { "item": item }))
    }

    function addAttachedMaskItem(item) {
        if (root.attachedMaskItems.includes(item)) return;
        root.attachedMaskItems.push(item);
    }

    function removeAttachedMaskItem(item) {
        root.attachedMaskItems = root.attachedMaskItems.filter(i => i !== item);
    }

    onAttachedMaskItemsChanged: {
        if (attachedMaskItems.length > 0) {
            S.GlobalFocusGrab.addDismissable(root.QsWindow.window);
        } else {
            S.GlobalFocusGrab.removeDismissable(root.QsWindow.window);
        }
    }

    Connections {
        target: S.GlobalFocusGrab
        function onDismissed() {
            root.attachedMaskItems = [];
            root.focusGrabDismissed();
        }
    }

    Component {
        id: regionComp
        Region {}
    }
}

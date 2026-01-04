import QtQuick
import Quickshell

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
    required property int screenWidth
    required property int screenHeight

    // Some info
    property int reservedTop: 0
    property int reservedBottom: 0
    property int reservedLeft: 0
    property int reservedRight: 0

    // Main stuff
    property var backgroundPolygon
    property Region maskRegion: Region {
        item: root
    }
}

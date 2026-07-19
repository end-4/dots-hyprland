import QtQuick
import Quickshell
import qs.modules.common

/*
 * Abstract widgets for an overlay. Doesn't contain any visuals.
 */
AbstractWidget {
    id: root

    property bool pinned: false // Whether to stay visible when the overlay is dismissed
    property bool clickthrough: true // When pinned, whether to allow clicks go through
}

pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Options toolbar
Toolbar {
    id: root

    // Use a synchronizer on these
    property var action
    property var selectionMode

    MaterialCookie {
        Layout.fillHeight: true
        Layout.leftMargin: 2
        Layout.rightMargin: 2
        implicitSize: 36 // Intentionally smaller because this one is brighter than others
        sides: 10
        amplitude: implicitSize / 44
        color: Appearance.colors.colPrimary
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 22
            color: Appearance.colors.colOnPrimary
            animateChange: true
            text: switch (root.action) {
                case RegionSelection.SnipAction.Copy:
                case RegionSelection.SnipAction.Edit:
                    return "content_cut";
                case RegionSelection.SnipAction.Search:
                    return "image_search";
                case RegionSelection.SnipAction.CharRecognition:
                    return "document_scanner";
                default:
                    return "";
            }
        }
    }

    IconAndTextToolbarButton {
        iconText: "activity_zone"
        text: Translation.tr("Rect")
        toggled: root.selectionMode === RegionSelection.SelectionMode.RectCorners
        onClicked: root.selectionMode = RegionSelection.SelectionMode.RectCorners
    }

    IconAndTextToolbarButton {
        iconText: "gesture"
        text: Translation.tr("Circle")
        toggled: root.selectionMode === RegionSelection.SelectionMode.Circle
        onClicked: root.selectionMode = RegionSelection.SelectionMode.Circle
    }

    IconToolbarButton {
        text: "close"
        colBackground: Appearance.colors.colLayer3
        onClicked: root.dismiss();
    }
}

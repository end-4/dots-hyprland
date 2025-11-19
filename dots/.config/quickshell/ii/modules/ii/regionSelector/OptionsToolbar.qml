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
    // Signals
    signal dismiss()

    MaterialShape {
        Layout.fillHeight: true
        Layout.leftMargin: 2
        Layout.rightMargin: 2
        implicitSize: 36 // Intentionally smaller because this one is brighter than others
        shape: switch (root.action) {
            case RegionSelection.SnipAction.Copy:
            case RegionSelection.SnipAction.Edit:
                return MaterialShape.Shape.Cookie4Sided;
            case RegionSelection.SnipAction.Search:
                return MaterialShape.Shape.Pentagon;
            case RegionSelection.SnipAction.CharRecognition:
                return MaterialShape.Shape.Sunny;
            case RegionSelection.SnipAction.Record:
            case RegionSelection.SnipAction.RecordWithSound:
                return MaterialShape.Shape.Gem;
            default:
                return MaterialShape.Shape.Cookie12Sided;
        }
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
                case RegionSelection.SnipAction.Record:
                case RegionSelection.SnipAction.RecordWithSound:
                    return "videocam";
                default:
                    return "";
            }
        }
    }

    ToolbarTabBar {
        id: tabBar
        tabButtonList: [
            {"icon": "activity_zone", "name": Translation.tr("Rect")},
            {"icon": "gesture", "name": Translation.tr("Circle")}
        ]
        currentIndex: root.selectionMode === RegionSelection.SelectionMode.RectCorners ? 0 : 1
        onCurrentIndexChanged: {
            root.selectionMode = currentIndex === 0 ? RegionSelection.SelectionMode.RectCorners : RegionSelection.SelectionMode.Circle;
        }
    }

}

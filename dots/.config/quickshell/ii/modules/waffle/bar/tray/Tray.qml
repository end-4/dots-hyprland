pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.synchronizer
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.bar

RowLayout {
    id: root

    property bool overflowOpen: false

    Layout.fillHeight: true
    spacing: 0

    BarIconButton {
        id: overflowButton

        visible: TrayService.unpinnedItems.length > 0
        checked: root.overflowOpen

        iconName: "chevron-down"
        iconMonochrome: true
        iconRotation: (Config.options.waffles.bar.bottom ? 180 : 0) + (root.overflowOpen ? 180 : 0)
        Behavior on iconRotation {
            animation: Looks.transition.rotate.createObject(this)
        }
        
        onClicked: {
            root.overflowOpen = !root.overflowOpen;
        }
    
        TrayOverflowMenu {
            id: trayOverflowLayout
            Synchronizer on active {
                property alias source: root.overflowOpen
            }
        }

        BarToolTip {
            extraVisibleCondition: overflowButton.shouldShowTooltip
            text: qsTr("Show hidden icons")
        }
    }

    Repeater {
        model: ScriptModel {
            values: TrayService.pinnedItems
        }
        delegate: TrayButton {
            required property var modelData
            item: modelData
        }
    }
}

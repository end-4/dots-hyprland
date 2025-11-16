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

        DropArea {
            id: pinDropArea
            anchors.fill: parent
            property bool willPin: false
            onEntered: willPin = true
            onExited: willPin = false
        }
    }

    Repeater {
        model: ScriptModel {
            values: TrayService.pinnedItems
        }
        delegate: TrayButton {
            id: trayButton
            required property var modelData
            item: modelData

            Drag.active: dragArea.drag.active
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            property real initialX
            property real initialY

            Behavior on x {
                animation: Looks.transition.move.createObject(this)
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: parent
                drag.axis: Drag.XAxis

                onPressed: (event) => {
                    trayButton.initialX = trayButton.x;
                    trayButton.initialY = trayButton.y;
                    trayButton.Drag.active = true;
                }
                onReleased: {
                    if (!dragArea.drag.active) {
                        trayButton.click();
                    } else {
                        if (pinDropArea.containsDrag && pinDropArea.willPin) {
                            // Quickshell would crash if we don't hide this item first. Took me fucking 3 hours to figure out...
                            trayButton.visible = false;
                            TrayService.togglePin(trayButton.item.id);
                            pinDropArea.willPin = false;
                        } else {
                            trayButton.x = trayButton.initialX;
                            trayButton.y = trayButton.initialY;
                        }
                    }
                }
            }
        }
    }
}

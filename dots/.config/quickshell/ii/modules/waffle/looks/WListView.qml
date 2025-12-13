import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

ListView {
    id: root

    boundsBehavior: Flickable.DragOverBounds

    ScrollBar.vertical: WScrollBar {}

    displaced: Transition {
        animations: [Looks.transition.enter.createObject(this, {
                property: "y"
            })]
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 1000 }
            NumberAnimation { properties: "x,y"; to: 100; duration: 1000 }
        }
    }

}

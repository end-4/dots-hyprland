pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.common as C
import qs.modules.common.functions as F
import qs.services as S
import qs.modules.common.widgets as W
import ".."

HBarWidgetContainer {
    id: root

    property bool showPopup: false
    readonly property bool vertical: C.Config.options.bar.vertical
    readonly property bool atBottom: C.Config.options.bar.bottom

    // Interactions
    property var morphedPanelParent: F.ObjectUtils.findParentWithProperty(root, "maskItems")
    onShowPopupChanged: {
        if (root.showPopup) {
            root.morphedPanelParent.addAttachedMaskItem(bgShape);
        } else {
            root.morphedPanelParent.removeAttachedMaskItem(bgShape);
        }
    }
    Connections {
        target: root.morphedPanelParent
        function onFocusGrabDismissed() {
            root.showPopup = false;
        }
    }

    // Background container shape
    property alias backgroundShape: bgShape
    property alias popupContentWidth: bgShape.popupContentWidth
    property alias popupContentHeight: bgShape.popupContentHeight
    property alias popupContentOffsetX: bgShape.popupContentOffsetX
    property alias popupContentOffsetY: bgShape.popupContentOffsetY

    background: Item {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: root.backgroundTopMargin
            leftMargin: root.backgroundLeftMargin
        }
        implicitWidth: root.backgroundWidth
        implicitHeight: root.backgroundHeight

        HBarWidgetShapeBackground {
            id: bgShape

            vertical: root.vertical
            atBottom: root.atBottom
            showPopup: root.showPopup
            
            backgroundWidth: root.backgroundWidth
            backgroundHeight: root.backgroundHeight
            startRadius: root.getBackgroundRadius(root.startSide)
            endRadius: root.getBackgroundRadius(root.endSide)
        }
    }
}

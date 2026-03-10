pragma ComponentBehavior: Bound
import QtQuick

import qs
import qs.modules.common.widgets
import ".."

HBarWidgetWithPopout {
    id: root

    HBarWidgetContent {
        id: contentRoot
        vertical: root.vertical
        atBottom: root.atBottom
        contentImplicitWidth: symbol.implicitWidth
        contentImplicitHeight: symbol.implicitHeight
        showPopup: false
        onClicked: GlobalStates.sessionOpen = true;

        MaterialSymbol {
            id: symbol
            anchors.centerIn: parent
            iconSize: 20
            text: "power_settings_new"
        }
    }
}

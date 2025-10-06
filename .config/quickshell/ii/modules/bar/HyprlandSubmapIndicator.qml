import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick.Layouts // For RowLayout

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    active: HyprlandSubmap.currentSubmap !== "global"
    visible: active

    property var iconMap: ({
        "resize": "aspect_ratio"
    })

    function getSubmapText(submapName) {
        if (submapName === "global") {
            return "";
        }
        if (root.iconMap[submapName]) {
            return root.iconMap[submapName] + " " + submapName;
        }
        return submapName;
    }

    sourceComponent: Item {
        implicitWidth: root.vertical ? null : contentLayout.implicitWidth
        implicitHeight: root.vertical ? contentLayout.implicitHeight : null

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialSymbol {
                id: iconItem
                visible: root.iconMap[HyprlandSubmap.currentSubmap] !== undefined && HyprlandSubmap.currentSubmap !== "global"
                text: root.iconMap[HyprlandSubmap.currentSubmap] || ""
                color: root.color
                iconSize: Appearance.font.pixelSize.small
                animateChange: true
            }

            StyledText {
                id: submapText
                visible: HyprlandSubmap.currentSubmap !== "global" && !root.iconMap[HyprlandSubmap.currentSubmap]
                text: HyprlandSubmap.currentSubmap
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.color
                animateChange: true
            }
        }
    }
}

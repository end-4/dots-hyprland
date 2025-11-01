import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    active: HyprlandSubmap.currentSubmap !== "global"
    visible: active

    property list<string> submapNames: []
    property list<string> submapIcons: []

    onActiveChanged: {
        if (active) {
            root.submapIcons = Config.options.submaps.icons;
            root.submapNames = Config.options.submaps.names;
        }
    }

    function getSubmapText(submapName) {
        if (submapName === "global") {
            return "";
        }
        let index = root.submapNames.indexOf(submapName);
        if (index !== -1) {
            return root.submapIcons[index] + " " + submapName;
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
                property int currentIndex: root.submapNames.indexOf(HyprlandSubmap.currentSubmap)
                visible: currentIndex !== -1 && HyprlandSubmap.currentSubmap !== "global"
                text: currentIndex !== -1 ? root.submapIcons[currentIndex] : ""
                color: root.color
                iconSize: Appearance.font.pixelSize.small
                animateChange: true
            }

            StyledText {
                id: submapText
                property int currentIndex: root.submapNames.indexOf(HyprlandSubmap.currentSubmap)
                visible: HyprlandSubmap.currentSubmap !== "global" && currentIndex === -1
                text: HyprlandSubmap.currentSubmap
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.color
                animateChange: true
            }
        }
    }
}

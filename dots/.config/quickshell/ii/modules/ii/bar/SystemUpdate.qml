import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true

    onClicked: {
        SystemUpdates.getUpdates();
        Quickshell.execDetached(["notify-send",
                                 Translation.tr("System Update"),
                                 Translation.tr("Refreshing package list")
                                 , "-a", "Shell"
                                ])
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            fill: 0
            text: "package_2"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
            text: SystemUpdates.updatesAvail
            Layout.alignment: Qt.AlignVCenter
        }
    }

    SystemUpdatePopup {
        id: systemUpdatesPopup
        hoverTarget: root
    }
}

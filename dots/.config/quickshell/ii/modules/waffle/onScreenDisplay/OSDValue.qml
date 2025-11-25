import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root
    required property string iconName
    property real value
    property bool showNumber: true

    property Timer timer: Timer {
        id: autoCloseTimer
        running: true
        interval: Config.options.osd.timeout
        repeat: false
        onTriggered: {
            root.close();
        }
    }

    contentItem: WPane {
        anchors.centerIn: parent
        borderColor: Looks.colors.ambientShadow

        contentItem: Item {
            // color: Looks.colors.bg1Base
            // radius: Looks.radius.medium
            implicitWidth: root.showNumber ? 192 : 170
            implicitHeight: 46

            RowLayout {
                id: contentRow
                anchors.fill: parent
                anchors.margins: 12

                spacing: 12

                FluentIcon {
                    Layout.alignment: Qt.AlignVCenter
                    icon: root.iconName
                    implicitSize: 18
                }

                WProgressBar {
                    id: progressBar
                    value: root.value
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: root.showNumber ? 0 : 3
                }

                WTextWithFixedWidth {
                    visible: root.showNumber
                    text: Math.round(root.value * 100)
                    // longestText: "100"
                    implicitWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

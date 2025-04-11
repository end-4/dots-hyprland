import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    required property string iconName
    required property double percentage
    property bool shown: true
    clip: true
    implicitWidth: resourceRowLayout.x < 0 ? 0 : childrenRect.width
    implicitHeight: childrenRect.height
    color: "transparent"

    RowLayout {
        spacing: 4
        id: resourceRowLayout
        x: shown ? 0 : -resourceRowLayout.width

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            lineWidth: 2
            value: percentage
            size: 26
            secondaryColor: Appearance.m3colors.m3secondaryContainer
            primaryColor: Appearance.m3colors.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                text: iconName
                font.pointSize: Appearance.font.pointSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Appearance.colors.colOnLayer1
            text: `${Math.round(percentage * 100)}%`
        }

        Behavior on x {
            NumberAnimation {
                duration: Appearance.animation.elementDecel.duration
                easing.type: Appearance.animation.elementDecel.type
            }
        }

    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }
}
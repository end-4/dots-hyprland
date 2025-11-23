import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

RowLayout {
    id: root

    required property string name
    property alias description: descriptionText.text
    property alias iconName: iconWidget.icon
    property alias checked: switchWidget.checked

    spacing: 10

    FluentIcon {
        id: iconWidget
        visible: !!root.iconName
        Layout.leftMargin: 12
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.alignment: Qt.AlignTop
        icon: root.iconName
        implicitSize: 18
    }

    ColumnLayout {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        spacing: 1

        // Name
        WText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pixelSize: Looks.font.pixelSize.large
            text: root.name
        }
        // Description
        WText {
            id: descriptionText
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Looks.colors.subfg
        }
    }

    MouseArea {
        Layout.rightMargin: 12
        implicitWidth: switchRow.implicitWidth
        implicitHeight: switchRow.implicitHeight
        onPressed: switchWidget.down = true
        onReleased: switchWidget.down = false
        onClicked: switchWidget.checked = !switchWidget.checked

        Row {
            id: switchRow
            spacing: 12

            WTextWithFixedWidth {
                longestText: "Off" // The larger one
                text: switchWidget.checked ? Translation.tr("On") : Translation.tr("Off")
                font.pixelSize: Looks.font.pixelSize.large
            }
            
            WSwitch {
                id: switchWidget
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}

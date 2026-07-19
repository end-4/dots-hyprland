import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitHeight: column.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    readonly property string dateTimeString: DateTime.time
    readonly property bool hasAmPm: dateTimeString.toLowerCase().includes("am") || dateTimeString.toLowerCase().includes("pm")

    Column {
        id: column
        anchors.centerIn: parent
        spacing: root.hasAmPm ? 6 : 0

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -4

            Repeater {
                model: root.dateTimeString.split(/[: ]/)
                delegate: StyledText {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: {
                        if (modelData.match(/am|pm/i))
                            return Appearance.font.pixelSize.smaller;
                        else
                            // Smaller "am"/"pm" text
                            return Appearance.font.pixelSize.large;
                    }
                    color: Appearance.colors.colOnLayer1
                    text: modelData.padStart(2, "0")
                }
            }
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colOnLayer1
            text: DateTime.shortDate
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        Bar.ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}

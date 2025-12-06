pragma ComponentBehavior: Bound

//TODO: fix imports to only what is necessary
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

ColumnLayout {
    id: clockColumn
    spacing: 6

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical

    Item {
        Layout.fillWidth: true
        implicitHeight: timeTextTop.font.pixelSize + (clockColumn.isVertical ? timeTextBottom.font.pixelSize + 10 : 0)
        implicitWidth: Math.max(timeTextTop.paintedWidth, timeTextBottom.paintedWidth)

        ClockText {
            id: timeTextTop
            text: clockColumn.isVertical ? DateTime.time.substring(0, 2) : DateTime.time
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            font {
                pixelSize: Config.options.background.widgets.clock.digital.font.size
                weight: Config.options.background.widgets.clock.digital.font.weight
                variableAxes: ({
                    "wdth": Config.options.background.widgets.clock.digital.font.width,
                    "ROND": Config.options.background.widgets.clock.digital.font.roundness
                })
            }
        }
        ClockText {
            id: timeTextBottom
            text: clockColumn.isVertical ? DateTime.time.substring(3, 5) : ""
            visible: clockColumn.isVertical

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            font {
                pixelSize: Config.options.background.widgets.clock.digital.font.size
                weight: Config.options.background.widgets.clock.digital.font.weight
                variableAxes: ({
                    "wdth": Config.options.background.widgets.clock.digital.font.width,
                    "ROND": Config.options.background.widgets.clock.digital.font.roundness
                })
            }
        }
    }
    
    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.topMargin: clockColumn.isVertical ? -10 : 0
        text: DateTime.longDate
    }
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
    }
}


    
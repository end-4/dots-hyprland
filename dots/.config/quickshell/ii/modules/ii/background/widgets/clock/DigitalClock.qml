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
    spacing: 4

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property var textHorizontalAlignment: Text.AlignHCenter

    ClockText {
        id: timeTextTop
        text: clockColumn.isVertical ? DateTime.time.substring(0, 2) : DateTime.time
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: Config.options.background.widgets.clock.digital.font.size
            weight: Config.options.background.widgets.clock.digital.font.weight
            family: Config.options.background.widgets.clock.digital.font.family
            variableAxes: ({
                "wdth": Config.options.background.widgets.clock.digital.font.width,
                "ROND": Config.options.background.widgets.clock.digital.font.roundness
            })
        }
    }

    ClockText {
        id: timeTextBottom
        text: DateTime.time.substring(3, 5)
        visible: clockColumn.isVertical
        color: clockColumn.colText
        Layout.topMargin: -40
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: Config.options.background.widgets.clock.digital.font.size
            weight: Config.options.background.widgets.clock.digital.font.weight
            family: Config.options.background.widgets.clock.digital.font.family
            variableAxes: ({
                "wdth": Config.options.background.widgets.clock.digital.font.width,
                "ROND": Config.options.background.widgets.clock.digital.font.roundness
            })
        }
    }
    
    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.topMargin: -20
        text: DateTime.longDate
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}


    
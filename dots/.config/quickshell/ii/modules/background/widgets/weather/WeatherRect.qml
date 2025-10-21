import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

import "../"

Item {
    implicitWidth: widget.widgetWidth
    implicitHeight: widget.widgetHeight

    Component.onCompleted: {
        widget.implicitHeight = implicitHeight
        widget.implicitWidth = implicitWidth
    }

    WeatherSymbols {
        id: symbols
    }

    DropShadow {
        source: weatherRect
        anchors.fill: weatherRect
        horizontalOffset: 0
        verticalOffset: 1
        radius: 12
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
        rotation: -widget.widgetRotation
    }

    Rectangle {
        id: weatherRect
        anchors.fill:parent
        radius: Appearance.rounding.full
        color: widget.colBackground
        rotation: -widget.widgetRotation

        StyledText {
            visible: true
            font.pixelSize: 60
            rotation: widget.widgetRotation
            color: widget.colText
            text: Weather.data?.temp.substring(0,Weather.data?.temp.length - 1) ?? "--°"
            Layout.alignment: Qt.AlignVCenter
            anchors {
                right: parent.right
                rightMargin: 15
                top: parent.top
                topMargin: 35
            }
        }

        MaterialSymbol {
            iconSize: 65
            color: widget.colText
            rotation: widget.widgetRotation
            text: symbols.codeToName[Weather.data.wCode] ?? "cached"
            Layout.alignment: Qt.AlignVCenter
            anchors {
                left: parent.left
                leftMargin: 15
                top: parent.top
                topMargin: 35
            }   
        }  
    }  
}
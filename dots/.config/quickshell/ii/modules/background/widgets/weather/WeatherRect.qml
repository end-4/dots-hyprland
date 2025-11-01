import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects



Item {
    id: widgetRect

    DropShadow {
        source: weatherRect
        anchors.fill: weatherRect
        horizontalOffset: 0
        verticalOffset: 1
        radius: 12
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
    }

    MaterialShape {
        shape: MaterialShape.Shape.Pill
        id: weatherRect
        color: widget.colBackground

        implicitSize: widget.widgetSize

        StyledText {
            visible: true
            font.pixelSize: 60
            color: widget.colText
            text: Weather.data?.temp.substring(0,Weather.data?.temp.length - 1) ?? "--°"
            Layout.alignment: Qt.AlignVCenter
            anchors {
                right: parent.right
                top: parent.top

                rightMargin: 15
                topMargin: 25
            }
        }

        MaterialSymbol {
            iconSize: 65
            color: widget.colText
            text: Icons.getWeatherName(Weather.data.wCode) ?? "cached"
            Layout.alignment: Qt.AlignVCenter
            anchors {
                left: parent.left
                bottom: parent.bottom
                
                leftMargin: 20
                bottomMargin: 10
            }   
        }  
    }  
}
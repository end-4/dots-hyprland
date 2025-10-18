import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../"

BackgroundWidget {
    id: widget

    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colText: Appearance.colors.colOnLayer1
    property int widgetRotation: 45

    x: Config.options.background.widgets.weatherX
    y: Config.options.background.widgets.weatherY

    onPositionChanged: {
        Config.options.background.widgets.weatherX = newX
        Config.options.background.widgets.weatherY = newY
    }

    implicitWidth: 200
    implicitHeight: 160

    Loader {
        active: true
        sourceComponent: Rectangle {
            id: cookieClock
            rotation: -widget.widgetRotation
            color: colBackground
            implicitWidth: widget.implicitWidth
            implicitHeight: widget.implicitHeight
            radius: Appearance.rounding.full
            StyledText {
                visible: true
                font.pixelSize: 70
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
                id: icon
                fill: 0
                text: codeToName[Weather.data.wCode]
                iconSize: 75
                rotation: widget.widgetRotation
                color: widget.colText
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

    readonly property var codeToName: ({
            "113": "clear_day",
            "116": "partly_cloudy_day",
            "119": "cloud",
            "122": "cloud",
            "143": "foggy",
            "176": "rainy",
            "179": "rainy",
            "182": "rainy",
            "185": "rainy",
            "200": "thunderstorm",
            "227": "cloudy_snowing",
            "230": "snowing_heavy",
            "248": "foggy",
            "260": "foggy",
            "263": "rainy",
            "266": "rainy",
            "281": "rainy",
            "284": "rainy",
            "293": "rainy",
            "296": "rainy",
            "299": "rainy",
            "302": "weather_hail",
            "305": "rainy",
            "308": "weather_hail",
            "311": "rainy",
            "314": "rainy",
            "317": "rainy",
            "320": "cloudy_snowing",
            "323": "cloudy_snowing",
            "326": "cloudy_snowing",
            "329": "snowing_heavy",
            "332": "snowing_heavy",
            "335": "snowing",
            "338": "snowing_heavy",
            "350": "rainy",
            "353": "rainy",
            "356": "rainy",
            "359": "weather_hail",
            "362": "rainy",
            "365": "rainy",
            "368": "cloudy_snowing",
            "371": "snowing",
            "374": "rainy",
            "377": "rainy",
            "386": "thunderstorm",
            "389": "thunderstorm",
            "392": "thunderstorm",
            "395": "snowing"
        })
}
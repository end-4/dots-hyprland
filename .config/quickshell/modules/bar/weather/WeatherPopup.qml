import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property real margin: 10
    implicitWidth: columnLayout.implicitWidth + margin * 2
    implicitHeight: columnLayout.implicitHeight + margin * 2
    color: Appearance.colors.colLayer0
    radius: 12
    clip: true
    border.color: Appearance.colors.colShadow
    border.width: 1

    ColumnLayout {
        id: columnLayout
        spacing: 5
        anchors.centerIn: root
        implicitWidth: Math.max(header.implicitWidth, gridLayout.implicitWidth)
        implicitHeight: gridLayout.implicitHeight

        // Header
        RowLayout {
            id: header
            spacing: 5
            Layout.fillWidth: parent
            Layout.alignment: Qt.AlignHCenter
            MaterialSymbol {
                fill: 0
                text: "location_on"
                iconSize: Appearance.font.pixelSize.huge
            }

            StyledText {
                text: WeatherService.data.city
                font.pixelSize: Appearance.font.pixelSize.title
                font.family: Appearance.font.family.title
                color: Appearance.colors.colOnLayer0
            }
        }

        // Metrics grid
        GridLayout {
            id: gridLayout
            columns: 2
            rowSpacing: 5
            columnSpacing: 5
            uniformCellWidths: true

            WeatherCard {
                title: "UV Index"
                symbol: "wb_sunny"
                value: WeatherService.data.uv
            }
            WeatherCard {
                title: "Wind"
                symbol: "air"
                value: `(${WeatherService.data.windDir}) ${WeatherService.data.wind}`
            }
            WeatherCard {
                title: "Precipitation"
                symbol: "rainy_light"
                value: WeatherService.data.precip
            }
            WeatherCard {
                title: "Humidity"
                symbol: "humidity_low"
                value: WeatherService.data.humidity
            }
            WeatherCard {
                title: "Visibility"
                symbol: "visibility"
                value: WeatherService.data.visib
            }
            WeatherCard {
                title: "Pressure"
                symbol: "readiness_score"
                value: WeatherService.data.press
            }
            WeatherCard {
                title: "Sunrise"
                symbol: "wb_twilight"
                value: WeatherService.data.sunrise
            }
            WeatherCard {
                title: "Sunset"
                symbol: "bedtime"
                value: WeatherService.data.sunset
            }
        }
    }
}

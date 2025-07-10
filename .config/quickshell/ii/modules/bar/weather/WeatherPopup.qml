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
    radius: Appearance.rounding.small
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant
    clip: true

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
                text: Weather.data.city
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
                value: Weather.data.uv
            }
            WeatherCard {
                title: "Wind"
                symbol: "air"
                value: `(${Weather.data.windDir}) ${Weather.data.wind}`
            }
            WeatherCard {
                title: "Precipitation"
                symbol: "rainy_light"
                value: Weather.data.precip
            }
            WeatherCard {
                title: "Humidity"
                symbol: "humidity_low"
                value: Weather.data.humidity
            }
            WeatherCard {
                title: "Visibility"
                symbol: "visibility"
                value: Weather.data.visib
            }
            WeatherCard {
                title: "Pressure"
                symbol: "readiness_score"
                value: Weather.data.press
            }
            WeatherCard {
                title: "Sunrise"
                symbol: "wb_twilight"
                value: Weather.data.sunrise
            }
            WeatherCard {
                title: "Sunset"
                symbol: "bedtime"
                value: Weather.data.sunset
            }
        }
    }
}

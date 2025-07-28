import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

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
    border.color: Appearance.colors.colLayer0Border
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
                title: Translation.tr("UV Index")
                symbol: "wb_sunny"
                value: Weather.data.uv
            }
            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "air"
                value: `(${Weather.data.windDir}) ${Weather.data.wind}`
            }
            WeatherCard {
                title: Translation.tr("Precipitation")
                symbol: "rainy_light"
                value: Weather.data.precip
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "humidity_low"
                value: Weather.data.humidity
            }
            WeatherCard {
                title: Translation.tr("Visibility")
                symbol: "visibility"
                value: Weather.data.visib
            }
            WeatherCard {
                title: Translation.tr("Pressure")
                symbol: "readiness_score"
                value: Weather.data.press
            }
            WeatherCard {
                title: Translation.tr("Sunrise")
                symbol: "wb_twilight"
                value: Weather.data.sunrise
            }
            WeatherCard {
                title: Translation.tr("Sunset")
                symbol: "bedtime"
                value: Weather.data.sunset
            }
        }
    }
}

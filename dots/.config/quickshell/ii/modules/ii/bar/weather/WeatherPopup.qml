import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root
    
    Item {
        anchors.centerIn: parent
        implicitWidth: gridLayout.implicitWidth + 8
        implicitHeight: columnLayout.implicitHeight + 8

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 8

            // Header
            RowLayout {
                id: header
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter 

                ColumnLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: 0

                    StyledText {
                        text: Weather.data.city
                        font {
                            weight: Font.Bold
                            pixelSize: Appearance.font.pixelSize.small
                        }
                        color: Appearance.colors.colOnSurface
                    }

                    StyledText {
                        text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
                        font {
                            weight: Font.Normal
                            pixelSize: Appearance.font.pixelSize.smaller
                        }
                        color: Appearance.colors.colOutline
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    StyledText {
                        text: Weather.data.temp
                        font {
                            weight: Font.SemiBold
                            pixelSize: Appearance.font.pixelSize.small * 2
                        }
                        color: Appearance.colors.colOnSurface
                    }

                    MaterialSymbol {
                        text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                        fill: 0
                        font.weight: Font.Normal
                        iconSize: Appearance.font.pixelSize.small * 2
                        color: Appearance.colors.colOnSurface
                    }
                }
            }

            // Metrics grid
            GridLayout {
                id: gridLayout
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                uniformCellWidths: true

                WeatherCard {
                    title: Translation.tr("UV Index")
                    symbol: "wb_sunny"
                    value: Weather.data.uv
                }
                WeatherCard {
                    title: Translation.tr("Wind")
                    symbol: "air"
                    value: `${Weather.data.windDirArrow} ${Weather.data.wind} ${Translation.tr(Weather.data.windUnit)}`
                }
                WeatherCard {
                    title: Translation.tr("Precipitation")
                    symbol: "rainy_light"
                    value: `${Weather.data.precip} ${Translation.tr(Weather.data.precipUnit)}`
                }
                WeatherCard {
                    title: Translation.tr("Humidity")
                    symbol: "humidity_low"
                    value: Weather.data.humidity
                }
                WeatherCard {
                    title: Translation.tr("Visibility")
                    symbol: "visibility"
                    value: `${Weather.data.visib} ${Translation.tr(Weather.data.visibUnit)}`
                }
                WeatherCard {
                    title: Translation.tr("Pressure")
                    symbol: "readiness_score"
                    value: `${Weather.data.press} ${Translation.tr(Weather.data.pressUnit)}`
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

            // Footer: last refresh
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh)
                font {
                    weight: Font.Normal
                    pixelSize: Appearance.font.pixelSize.smaller
                }
                color: Appearance.colors.colOutline
            }
        }
    }
}
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root
    keepOpenOnHover: true

    Item {
        // fill the popup background so the content stays centred inside its padding
        anchors.fill: parent
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        RippleButton {
            id: refreshButton
            anchors {
                top: columnLayout.top
                right: columnLayout.right
            }
            implicitWidth: 28
            implicitHeight: 28
            buttonRadius: Appearance.rounding.full
            onClicked: Weather.getData()

            contentItem: Item {
                id: refreshIcon
                implicitWidth: 24
                implicitHeight: 24

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                RotationAnimator {
                    target: refreshIcon
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: Weather.loading
                    onRunningChanged: {
                        if (!running)
                            refreshIcon.rotation = 0;
                    }
                }
            }

            StyledToolTip {
                text: Translation.tr("Refresh")
            }
        }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        implicitWidth: Math.max(header.implicitWidth, gridLayout.implicitWidth)
        // natural content height: header, cards and footer all count
        spacing: 5

        // Header
        ColumnLayout {
            id: header
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                MaterialSymbol {
                    fill: 0
                    font.weight: Font.Medium
                    text: "location_on"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Weather.data.city
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
            // big temperature: the main information of the popup
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                MaterialSymbol {
                    fill: 0
                    text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                    iconSize: Appearance.font.pixelSize.title * 1.5
                    color: Appearance.colors.colOnSurface
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    id: temp
                    text: Weather.data.temp
                    font {
                        pixelSize: Appearance.font.pixelSize.title * 1.6
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurface
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
            }
        }

        // Metrics grid
        GridLayout {
            id: gridLayout
            columns: 2
            rowSpacing: 5
            columnSpacing: 5
            uniformCellWidths: true

            // uv card removed
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
            // visibility card removed
            WeatherCard {
                title: Translation.tr("Pressure")
                symbol: "readiness_score"
                value: Weather.data.press
            }
            // sunrise/sunset cards removed
        }

        // Footer: last refresh
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh)
            font {
                weight: Font.Medium
                pixelSize: Appearance.font.pixelSize.smaller
            }
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
    } // end of refresh wrapper
}

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.bar.weather

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"
    needsColText: true

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    // Secondary color with slightly less contrast for subtitles
    property color colTextSecondary: ColorUtils.transparentize(colText, 0.3)

    StyledDropShadow {
        target: card
    }

    // Card background with transparent/adaptive styling
    Rectangle {
        id: card
        implicitWidth: 180
        implicitHeight: contentLayout.implicitHeight + 24
        radius: Appearance.rounding.large
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.5)
        border.width: 1
        border.color: ColorUtils.transparentize(root.colText, 0.8)
        layer.enabled: false

        ColumnLayout {
            id: contentLayout
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // Weather icon + Temperature row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    iconSize: 48
                    color: root.colText
                    text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                }

                StyledText {
                    font {
                        pixelSize: 42
                        family: Appearance.font.family.expressive
                        weight: Font.Medium
                    }
                    color: root.colText
                    text: Weather.data?.temp ?? "--°"
                }
            }

            // Weather condition
            StyledText {
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
                color: root.colTextSecondary
                text: Weather.data?.wText ?? "Loading..."
            }

            // Location row
            RowLayout {
                spacing: 4

                MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.small
                    color: root.colTextSecondary
                    text: "location_on"
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colTextSecondary
                    text: Weather.data?.city ?? "Unknown"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true

            onEntered: weatherPopup.open()
            onExited: weatherPopup.close()
        }

        WeatherPopup {
            id: weatherPopup
        }
    }
}

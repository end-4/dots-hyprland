import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

import "../"
import "./cookieClock"

BackgroundWidget {
    id: widget

    x: Config.options.background.clock.x
    y: Config.options.background.clock.y

    scaleMultiplier: Config.options.background.clock.scale

    property bool screenLocked: GlobalStates.screenLocked
    onScreenLockedChanged: {
        if (screenLocked) {
            x = 960 - implicitWidth / 2 - wallpaper.x
            y = 540 - implicitHeight / 2 - wallpaper.y
        }
        else {
            x = Config.options.background.clock.x
            y = Config.options.background.clock.y
        }
    } 

    onPositionChanged: {
        Config.options.background.clock.x = newX
        Config.options.background.clock.y = newY
    }

    Loader {
        active: Config.options.background.clock.style === "cookie"
        sourceComponent: ColumnLayout{
            CookieClock {
                id: cookieClock
                Component.onCompleted: {
                    widget.implicitWidth = implicitWidth
                    widget.implicitHeight = implicitHeight
                }
            }
            CookieQuote {
                visible: Config.options.background.showQuote
                anchors {
                    top: cookieClock.bottom
                    topMargin: 20
                    horizontalCenter: cookieClock.horizontalCenter
                }
            }
        }
    }
    
    Loader {
        active: Config.options.background.clock.style === "digital"
        sourceComponent:  ColumnLayout {
            scale: Config.options.background.clock.scale
            id: clockColumn
            spacing: 6
            Component.onCompleted: {
                widget.implicitWidth = implicitWidth
                widget.implicitHeight = implicitHeight
            }
            ClockText {
                font.pixelSize: 90
                text: DateTime.time
            }
            ClockText {
                Layout.topMargin: -10
                text: DateTime.date
            }
            ClockText {
                visible: Config.options.background.showQuote
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: 350
                    italic: true
                }
                text: Config.options.background.quote
            }
        }
    }
    


    component ClockText: StyledText {
        Layout.fillWidth: true
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: Font.DemiBold
        }
        horizontalAlignment: bgRoot.textHorizontalAlignment
        color: bgRoot.colText
        style: Text.Raised
        styleColor: Appearance.colors.colShadow
        animateChange: true
    }
}
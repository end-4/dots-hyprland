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

    property bool screenLocked: GlobalStates.screenLocked
    scaleMultiplier: Config.options.background.clock.scale
    
    onScreenLockedChanged: screenLocked ? centerOnScreen() : restorePosition()
    onPositionChanged: savePosition(newX, newY)

    function centerOnScreen() {
        // for lock screen
        x = bgRoot.monitor.width / 2 - implicitWidth / 2 - wallpaper.x
        y = bgRoot.monitor.height / 2 - implicitHeight / 2 - wallpaper.y
    }
    function restorePosition() {
        // after unlocking
        x = Config.options.background.clock.x
        y = Config.options.background.clock.y
    }
    function savePosition(xPos, yPos) {
        Config.options.background.clock.x = xPos
        Config.options.background.clock.y = yPos
    }

    Loader {
        active: Config.options.background.clock.style === "cookie"
        sourceComponent: ColumnLayout {
            Component.onCompleted: {
                widget.implicitWidth = implicitWidth
                widget.implicitHeight = implicitHeight
            }
            CookieClock {
                id: cookieClock
                Component.onCompleted: updateImplicitSize()
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
        scale: Config.options.background.clock.scale
        active: Config.options.background.clock.style === "digital"
        sourceComponent:  ColumnLayout {
            spacing: 5
            Component.onCompleted: {
                widget.implicitWidth = implicitWidth
                widget.implicitHeight = implicitHeight
            }
            ClockText { font.pixelSize: 90; text: DateTime.time }
            ClockText { Layout.topMargin: -10; text: DateTime.date }
            ClockText {
                text: Config.options.background.quote
                visible: Config.options.background.showQuote
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Thin
                    italic: true
                }
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
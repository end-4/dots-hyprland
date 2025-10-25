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

    property bool screenLocked: GlobalStates.screenLocked
    onScreenLockedChanged: screenLocked ? centerOnScreen() : restorePosition()

    scaleMultiplier: Config.options.background.clock.scale
    lockPosition: Config.options.background.clock.lockPosition

    x: GlobalStates.screenLocked ? centerOnScreen()[0] : restorePosition()[0]
    y: GlobalStates.screenLocked ? centerOnScreen()[1] : restorePosition()[1]

    onMiddleClicked: Config.options.background.clock.lockPosition = !Config.options.background.clock.lockPosition

    function centerOnScreen() {
        // for lock screen
        x = bgRoot.monitor.width / 2 - implicitWidth / 2 - wallpaper.x
        y = bgRoot.monitor.height / 2 - implicitHeight / 2 - wallpaper.y
        return [bgRoot.monitor.width / 2 - implicitWidth / 2 - wallpaper.x,bgRoot.monitor.height / 2 - implicitHeight / 2 - wallpaper.y]
    }
    function restorePosition() {
        // after unlocking
        x = Config.options.background.clock.x
        y = Config.options.background.clock.y
        return [Config.options.background.clock.x,Config.options.background.clock.y]
    }
    function savePosition(xPos, yPos) {
        Config.options.background.clock.x = xPos
        Config.options.background.clock.y = yPos
    }

    Loader {
        id: cookieClockLoader
        active: Config.options.background.clock.style === "cookie"
        sourceComponent: ColumnLayout {
            Component.onCompleted: {
                widget.implicitWidth = implicitWidth
                widget.implicitHeight = implicitHeight
            }
            CookieClock {
                id: cookieClock
            }
            CookieQuote {
                visible: GlobalStates.screenLocked && Config.options.lock.showLockedText || Config.options.background.showQuote && Config.options.background.quote !== ""
                anchors {
                    top: cookieClock.bottom
                    topMargin: 20
                    horizontalCenter: cookieClock.horizontalCenter
                }
            }
        }
    }
    
    Loader {
        id: digitalClockLoader
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
                text: GlobalStates.screenLocked && Config.options.lock.showLockedText ? "Locked" :
                      Config.options.background.showQuote ? Config.options.background.quote : ""
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
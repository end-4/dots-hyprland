import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "../"
import "./cookieClock"

BackgroundWidget {
    id: widget

    property color dominantColor: widget.collectorData.dominant_color
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        return (GlobalStates.screenLocked) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
    }

    property bool screenLocked: GlobalStates.screenLocked
    property bool centerClock: Config.options.lock.centerClock && screenLocked
    onScreenLockedChanged: centerClock ? centerOnScreen() : restorePosition()

    onMiddleClicked: Config.options.background.clock.lockPosition = !Config.options.background.clock.lockPosition
    scaleMultiplier: Config.options.background.clock.scale
    lockPosition: Config.options.background.clock.lockPosition

    x: centerClock ? centerOnScreen()[0] : restorePosition()[0]
    y: centerClock ? centerOnScreen()[1] : restorePosition()[1]

    leastBusyMode: Config.options.background.widgets.leastBusyPlacedWidget === "clock"
    onSetPosToLeastBusy: {
        Config.options.background.clock.x = collectorData.position_x 
        Config.options.background.clock.y = collectorData.position_y
        restorePosition()
    }

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
        //horizontalAlignment: bgRoot.textHorizontalAlignment
        color: widget.colText
        style: Text.Raised
        styleColor: Appearance.colors.colShadow
        animateChange: true
    }
}
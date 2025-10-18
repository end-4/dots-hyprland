import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

import "./widgets"

Item {
    id: root
    z: 1
    anchors.fill: parent
    
    Loader {
        x: wallpaper.x; y: wallpaper.y
        active: Config.options.background.clock.show
        sourceComponent: ClockWidget {}
    }

    Loader {
        x: wallpaper.x; y: wallpaper.y
        active: Config.options.background.weather.show && !GlobalStates.screenLocked
        sourceComponent: WeatherWidget {}
    }

   
    
}
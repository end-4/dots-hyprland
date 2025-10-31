import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

import "../"
import "./weather"

BackgroundWidget {
    id: widget

    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colText: Appearance.colors.colOnLayer1
    property int widgetSize: 160

    implicitWidth: widget.widgetSize
    implicitHeight: widget.widgetSize
    
    scaleMultiplier: Config.options.background.weather.scale
    x: Config.options.background.weather.x
    y: Config.options.background.weather.y

    lockPosition: Config.options.background.weather.lockPosition
    onMiddleClicked: Config.options.background.weather.lockPosition = !Config.options.background.weather.lockPosition
    
    leastBusyMode: Config.options.background.widgets.leastBusyPositionWidget === "weather"
    onSetPosToLeastBusy: {
        Config.options.background.weather.x = collectorData.position_x 
        Config.options.background.weather.y = collectorData.position_y
        restorePosition()
    }

    function savePosition(xPos, yPos) {
        Config.options.background.weather.x = xPos
        Config.options.background.weather.y = yPos
    }
    onRightClicked: {
        Weather.getData();
        Quickshell.execDetached(["notify-send", 
            Translation.tr("Weather"), 
            Translation.tr("Refreshing (manually triggered)")
            , "-a", "Shell"
        ])
    }

    Loader {
        id: weatherLoader
        active: Config.options.background.weather.show
        sourceComponent: WeatherRect {}
    }
}
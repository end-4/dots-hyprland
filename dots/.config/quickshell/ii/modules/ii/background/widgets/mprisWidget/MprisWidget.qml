pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.mediaControls

AbstractBackgroundWidget {
    id: root

    configEntryName: "mprisWidget"

    readonly property var activePlayer: MprisController.activePlayer
    readonly property bool hasPlayer: activePlayer != null

    implicitWidth: Config.options.background.widgets.mprisWidget.width
    implicitHeight: Config.options.background.widgets.mprisWidget.height

    visibleWhenLocked: false
    opacity: hasPlayer && !GlobalStates.screenLocked ? 1 : 0

    readonly property var roundingMap: [
        Appearance.rounding.unsharpen,
        Appearance.rounding.verysmall,
        Appearance.rounding.small,
        Appearance.rounding.normal,
        Appearance.rounding.large,
        Appearance.rounding.verylarge,
        Appearance.rounding.full
    ]
    readonly property real widgetRadius: roundingMap[Config.options.background.widgets.mprisWidget.rounding] ?? Appearance.rounding.normal

    PlayerControl {
        id: playerControl
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        player: root.activePlayer
        radius: root.widgetRadius
    }
}

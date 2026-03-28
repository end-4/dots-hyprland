import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root
    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale
    
    readonly property var configEntry: Config?.options?.background?.widgets[configEntryName]
    
    readonly property bool baseVisibility: GlobalStates.screenLocked ? (configEntry?.showWhenLocked ?? false) : true

    x: 0
    y: scaledScreenHeight - height
    width: scaledScreenWidth
}
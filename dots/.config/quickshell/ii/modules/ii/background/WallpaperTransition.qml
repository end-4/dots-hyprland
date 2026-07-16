pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.models.hyprland

Item {
    id: root

    required property Image wallpaper
    required property HyprlandMonitor monitor

    readonly property int cfgDuration: Math.max(50, Config?.options?.background?.transition?.duration ?? 600)
    readonly property bool cfgEnabled: Config?.options?.background?.transition?.enable ?? true

    property bool animating: false
    anchors.fill: parent
    visible: animating
    z: 1

    HyprlandConfigOption {
        id: hyprlandAnimations
        key: "animations:enabled"
    }

    function play(oldSource, newSource) {
        if (!root.cfgEnabled || !oldSource || !newSource || oldSource === newSource) {
            wallpaper.source = newSource;
            return;
        }
        if (hyprlandAnimations.value === false) {
            wallpaper.source = newSource;
            return;
        }

        frozenWallpaper.sourceSize = wallpaper.sourceSize;
        frozenWallpaper.source = oldSource;
        frozenWallpaper.visible = true;
        frozenWallpaper.opacity = 1;

        wallpaper.source = newSource;

        root.animating = true;
        fadeAnim.duration = root.cfgDuration;
        fadeAnim.restart();
    }

    function _endTransition() {
        frozenWallpaper.visible = false;
        frozenWallpaper.source = "";
        root.animating = false;
    }

    Image {
        id: frozenWallpaper
        anchors.fill: parent
        cache: true
        retainWhileLoading: true
        smooth: false
        fillMode: Image.PreserveAspectCrop
        visible: false
        z: 0
    }

    NumberAnimation {
        id: fadeAnim
        target: frozenWallpaper
        property: "opacity"
        from: 1
        to: 0
        easing.type: Easing.InOutCubic
        onStopped: root._endTransition()
    }
}

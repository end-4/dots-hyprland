import QtQuick
import qs.modules.common

// Yes, this is (mostly) a copy of FadeLoader.
// The animation of a Behavior cannot be changed... I'd love to be proven wrong.
Loader {
    id: root
    property bool shown: true
    property alias fade: opacityBehavior.enabled
    property alias animation: opacityBehavior.animation
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0

    Behavior on opacity {
        id: opacityBehavior
        animation: Looks.transition.opacity.createObject(null)
    }
}

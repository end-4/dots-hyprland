pragma ComponentBehavior: Bound
import QtQuick

AbstractChoreographable {
    id: root

    progress: 0
    property bool vertical: true
    property bool reverseDirection: false
    property real distance: 15

    readonly property real directionMultiplier: reverseDirection ? -1 : 1

    Component.onCompleted: syncProgress()
    onProgressChanged: syncProgress()

    function syncProgress() {
        const progressDistance = distance * (1 - progress) * directionMultiplier;
        root.child.opacity = progress
        if (vertical) {
            root.child.y = progressDistance
        } else {
            root.child.x = progressDistance
        }
    }
}

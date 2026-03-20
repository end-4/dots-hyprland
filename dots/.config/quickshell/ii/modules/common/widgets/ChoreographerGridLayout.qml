pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    columns: 1
    property real totalDuration: 250
    property real interval: totalDuration / count

    default property list<QtObject> choreographableChildren
    readonly property int count: choreographableChildren.length
    children: choreographableChildren

    property bool shown: false
    onShownChanged: {
        // When hiding, hide all at once
        if (!shown) {
            for (var i = 0; i < count; i++) {
                choreographableChildren[i].progress = 0;
            }
        }
        // When showing, choreograph
        root.choreographIndex = 0;
    }
    property int choreographIndex: count
    Timer {
        id: choreographTimer
        interval: root.interval
        property bool step: root.shown && root.choreographIndex < root.count
        running: step
        repeat: step
        onTriggered: {
            const index = root.choreographIndex;
            root.choreographableChildren[index].progress = 1;
            root.choreographIndex++;
        }
    }
}

import QtQuick

Rectangle {
    id: root

    // https://m3.material.io/foundations/interaction/states/state-layers
    enum State {
        Hover, Focus, Press, Drag
    }

    property var state: StateLayer.State.Hover
    opacity: switch(state) {
        case StateLayer.State.Hover: return 0.08;
        case StateLayer.State.Focus: return 0.1;
        case StateLayer.State.Press: return 0.1;
        case StateLayer.State.Drag: return 0.16;
        default: return 0;
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import "../"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./toggles"

Item {
    id: root
    // Required specs
    property int columns: 4
    property int rowHeight: 65
    property int gap: 16
    property int columnWidth: 90

    // Computed dimensions
    width: columns * columnWidth + (columns - 1) * gap
    implicitHeight: flow.implicitHeight + gap * 2

    Flow {
        id: flow
        anchors.fill: parent
        anchors.topMargin: root.gap
        anchors.bottomMargin: root.gap
        spacing: root.gap
        // Ensure items wrap within the width
        width: root.width

        Repeater {
            model: Config.toggleModel
            delegate: Loader {
                id: loader
                source: model.name ? "./toggles/" + model.name + ".qml" : ""
                visible: item ? item.isSupported : true
                width: model.span * root.columnWidth + (model.span - 1) * root.gap
                height: root.rowHeight
                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.error("Failed to load toggle component: " + source);
                    }
                }
                onLoaded: {
                    if (item && item.hasOwnProperty("sizeType")) {
                        item.sizeType = model.span;
                    }
                    // loader.visible = item.isSupported;
                    item.onIsSupportedChanged.connect(function () {
                        loader.visible = item.isSupported;
                    // console.warn(item , " isSupported has changed : ", item.isSupported)

                    });
                }
            }
        }
    }

    // Debug border
    Rectangle {
        anchors.fill: parent
        border.color: "pink"
        border.width: 0
        color: "transparent"
    }
}

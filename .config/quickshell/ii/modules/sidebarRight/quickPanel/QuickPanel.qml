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

    ListModel {
        id: items

        Component.onCompleted: {
            if (Config?.options?.quickToggle?.toggles?.length > 0) {
                let toggles = Config.options.quickToggle.toggles;
                let spans = Config.options.quickToggle.spans || [];
                let tempArray = [];

                // Create array of objects to sort
                for (let i = 0; i < toggles.length; i++) {
                    tempArray.push({
                        name: toggles[i],
                        span: Math.max(1, Math.min(2, spans[i] || 1))
                    });
                }

                // Sort by span (descending) for larger-first layout if enabled in config
                if(Config.options.quickToggle.sorted)
                tempArray.sort((a, b) => b.span - a.span);

                // Append sorted items to ListModel
                tempArray.forEach(item => {
                    items.append({
                        name: item.name,
                        span: item.span
                    });
                });
            }
        }
    }

    Flow {
        id: flow
        anchors.fill: parent
        anchors.topMargin: root.gap
        anchors.bottomMargin: root.gap
        spacing: root.gap
        // Ensure items wrap within the width
        width: root.width

        Repeater {
            model: items
            delegate: Rectangle {
                id: itemRect
                width: (model.span * root.columnWidth) + ((model.span - 1) * root.gap)
                height: root.rowHeight
                color: "transparent"

                Loader {
                    id: loader
                    anchors.fill: parent
                    source: model.name ? "./toggles/" + model.name + ".qml" : ""
                    onStatusChanged: {
                        if (status === Loader.Error) {
                            console.error("Failed to load toggle component: " + source)
                        }
                    }
                    onLoaded: {
                        if (item && item.hasOwnProperty("sizeType")) {
                            item.sizeType = model.span
                        }
                        itemRect.visible = item.visible

                    }
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

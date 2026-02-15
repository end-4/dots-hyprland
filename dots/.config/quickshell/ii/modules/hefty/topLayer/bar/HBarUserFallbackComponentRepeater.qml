pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common as C
import qs.modules.common.widgets as W

Repeater {
    id: root

    readonly property string invisibleItem: "_invisible"
    required property list<var> componentNames
    property string context: Quickshell.shellPath("modules/hefty/topLayer/bar/widgets")


    model: {
        const m = componentNames.map(item => {
            if (item instanceof Array) 
                return ({"type": "container", "value": item});
            else if (item === root.invisibleItem)
                return ({"type": "invisible", "value": item});
            else
                return ({"type": "component", "value": item});
        });
        for (var i = 0;i < m.length; i++) {
            const item = m[i];
            if (item.type === "container" || item.type === "component") {
                item.startSide = (i === 0) || (m[i - 1].type !== m[i].type);
                item.endSide = (i + 1 >= m.length) || (m[i + 1].type !== m[i].type);
            }
        }
        // print(JSON.stringify(m, null, 2));
        return m;
    }
    delegate: DelegateChooser {
        role: "type"

        DelegateChoice {
            roleValue: root.invisibleItem
            delegate: Item { visible: false }
        }
        
        DelegateChoice {
            roleValue: "component"
            delegate: W.UserFallbackLoader {
                required property var modelData
                required property int index
                componentName: modelData.value
                context: root.context
                property bool startSide: index === 0
                property bool endSide: index === root.model.length - 1
            }
        }

        DelegateChoice {
            roleValue: "container"
            delegate: HBarGroupContainer {
                id: group
                required property var modelData
                startSide: modelData.startSide
                endSide: modelData.endSide
                
                Repeater {
                    id: containerRepeater
                    model: group.modelData.value
                    delegate: W.UserFallbackLoader {
                        required property var modelData
                        required property int index
                        componentName: modelData
                        context: root.context
                        property bool startSide: index === 0
                        property bool endSide: index === group.modelData.value.length - 1
                    }
                }
            }
        }
    }
}
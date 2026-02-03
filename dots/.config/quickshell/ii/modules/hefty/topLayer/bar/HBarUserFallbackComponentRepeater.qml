pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common as C
import qs.modules.common.widgets as W

Repeater {
    id: root

    required property list<var> componentNames
    property string context: Quickshell.shellPath("modules/hefty/topLayer/bar/widgets")

    model: {
        const m = componentNames.map(item => {
            if (item instanceof Array) 
                return ({"type": "container", "value": item});
            else
                return ({"type": "component", "value": item});
        });
        for (var i = 0;i < m.length; i++) {
            const item = m[i];
            if (item.type === "container") {
                item.startSide = (i === 0) || (m[i - 1].type !== "container");
                item.endSide = (i + 1 >= m.length) || (m[i + 1].type !== "container");
            }
        }
        // print(JSON.stringify(m, null, 2));
        return m;
    }
    delegate: DelegateChooser {
        role: "type"
        
        DelegateChoice {
            roleValue: "component"
            delegate: W.UserFallbackLoader {
                required property var modelData
                componentName: modelData.value
                context: root.context
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
                    model: group.modelData.value
                    delegate: W.UserFallbackLoader {
                        required property var modelData
                        componentName: modelData
                        context: root.context
                    }
                }
            }
        }
    }
}
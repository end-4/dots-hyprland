pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell

Singleton {
    id: root
    
    property StackView stackView

    function push(component) {
        if (stackView) {
            stackView.push(component)
        }
    }

    function back() {
        if (stackView && stackView.depth > 1) {
            stackView.pop()
        }
    }
}

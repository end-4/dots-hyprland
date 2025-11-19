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
            item = stackView.push(component)
            stackView.implicitWidth = item.implicitWidth
            stackView.implicitHeight = item.implicitHeight
        }
    }

    function back() {
        if (stackView && stackView.depth > 1) {
            stackView.pop()
        }
    }
}

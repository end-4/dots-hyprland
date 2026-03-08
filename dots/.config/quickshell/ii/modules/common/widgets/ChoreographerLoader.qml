pragma ComponentBehavior: Bound
import QtQuick

FadeLoader {
    id: root    
    onActiveChanged: item.shown = true
}

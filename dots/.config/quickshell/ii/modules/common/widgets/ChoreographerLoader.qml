pragma ComponentBehavior: Bound
import QtQuick

FadeLoader {
    id: root    
    onActiveChanged: if (active) item.shown = true
}

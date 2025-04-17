import QtQuick

MouseArea {
    anchors.fill: parent
    onPressed:  mouse.accepted = false
    cursorShape: Qt.PointingHandCursor 
}
import QtQuick

MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => mouse.accepted = false
    cursorShape: Qt.PointingHandCursor
}
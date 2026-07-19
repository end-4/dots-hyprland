import QtQuick

MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton // Only for hover
    hoverEnabled: true
    cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
}

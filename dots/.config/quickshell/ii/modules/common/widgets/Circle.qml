import QtQuick

Rectangle {
    property real diameter

    implicitWidth: diameter
    implicitHeight: diameter
    radius: diameter / 2
}

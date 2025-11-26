import QtQuick

Rectangle {
    property double diameter

    implicitWidth: diameter
    implicitHeight: diameter
    radius: diameter / 2
}

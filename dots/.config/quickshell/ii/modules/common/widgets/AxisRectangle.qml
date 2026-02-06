pragma ComponentBehavior: Bound
import QtQuick

StyledRectangle {
    id: root
    
    property bool vertical: false
    property real startRadius
    property real endRadius

    topLeftRadius: startRadius
    topRightRadius: vertical ? startRadius : endRadius
    bottomLeftRadius: vertical ? endRadius : startRadius
    bottomRightRadius: endRadius
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property alias text: textWidget.text
    property alias horizontalAlignment: textWidget.horizontalAlignment
    property alias verticalAlignment: textWidget.verticalAlignment
    property alias font: textWidget.font
    property alias color: textWidget.color

    // In many cases the baseline is a bit high to accomodate the dangling parts of "g" and "y", 
    // making most text (especiall number-only text) not well-balanced.
    // This adjusts the rounding to make sure the text gets lowered if not internally pixel-aligned
    property bool lowerBias: true

    implicitWidth: textMetrics.width
    implicitHeight: textMetrics.height

    TextMetrics {
        id: textMetrics
        font: root.font
        text: root.text
    }

    StyledText {
        id: textWidget
        anchors.horizontalCenter: parent.horizontalCenter
        y: {
            const value = (parent.height - textMetrics.height) / 2;
            return root.lowerBias ? Math.ceil(value) : Math.round(value);
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}

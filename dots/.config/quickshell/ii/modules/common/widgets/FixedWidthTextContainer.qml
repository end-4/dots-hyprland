import QtQuick

Item {
    id: root

    property alias longestText: longestTextMetrics.text
    property alias font: longestTextMetrics.font

    implicitWidth: longestTextMetrics.width
    implicitHeight: longestTextMetrics.height

    TextMetrics {
        id: longestTextMetrics
        text: root.longestText
    }
}

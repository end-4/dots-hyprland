import QtQuick
import qs.services
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var toplevel
    property var windowData
    property var monitorData
    property bool isSelected: false
    property bool captureEnabled: true
    property real cardWidth: 220
    property real cardHeight: 124
    property int labelHeight: 36
    property int borderWidth: 2

    width: cardWidth
    height: cardHeight + labelHeight

    property string address: `0x${toplevel?.HyprlandToplevel?.address ?? ""}`
    property string title: windowData?.title ?? toplevel?.title ?? ""
    property string class_: windowData?.class ?? toplevel?.appId ?? ""
    property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(class_), "image-missing")

    Item {
        id: imageFrame
        width: root.cardWidth
        height: root.cardHeight
        anchors.top: parent.top
        clip: true

        ScreencopyView {
            id: preview
            anchors.centerIn: parent
            visible: root.captureEnabled && root.toplevel !== null
            property real sourceAspect: sourceSize.width > 0 && sourceSize.height > 0
                ? sourceSize.width / sourceSize.height
                : root.cardWidth / root.cardHeight
            width: Math.max(parent.width, parent.height * sourceAspect)
            height: Math.max(parent.height, parent.width / sourceAspect)
            captureSource: root.captureEnabled && root.toplevel !== null
                ? root.toplevel
                : null
            live: false
            paintCursor: true
            constraintSize: Qt.size(root.cardWidth, root.cardHeight)
            Component.onCompleted: {
                if (root.captureEnabled && root.toplevel !== null) captureFrame()
            }
            onVisibleChanged: {
                if (!visible) {
                    captureFrameCalled = false
                } else if (!captureFrameCalled && root.captureEnabled && root.toplevel !== null) {
                    captureFrameCalled = true
                    captureFrame()
                }
            }
            property bool captureFrameCalled: false
        }

        Image {
            id: iconFallback
            anchors.centerIn: parent
            width: 40
            height: 40
            source: root.iconPath
            sourceSize: Qt.size(width, height)
            visible: !preview.hasContent
            opacity: 0.8
        }

        Rectangle {
            id: innerBorder
            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.small
            border.width: root.isSelected ? 3 : root.borderWidth
            border.color: root.isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
        }
    }

    Column {
        anchors {
            top: imageFrame.bottom
            left: parent.left
            right: parent.right
            topMargin: 4
        }
        spacing: 1

        StyledText {
            width: parent.width
            text: root.title.length > 20 ? root.title.substring(0, 20) + "…" : root.title
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideMiddle
            visible: root.title.length > 0
        }

        Row {
            width: parent.width
            spacing: 4
            visible: root.class_.length > 0

            Image {
                width: 14
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                source: root.iconPath
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }

            StyledText {
                width: parent.width - 18
                text: root.class_
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideMiddle
            }
        }
    }
}

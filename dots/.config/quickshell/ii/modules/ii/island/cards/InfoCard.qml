import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.island

// Generic info card dropped by providers (weather, disk, clipboard image, long
// command, runaway process...). Optional image thumbnail and up to two buttons.
RowLayout {
    id: root
    property var ev
    readonly property var p: ev?.payload ?? ({})
    readonly property color accent: (p.accent ?? "") !== "" ? p.accent : Appearance.colors.colPrimary
    readonly property string image: p.image ?? ""
    spacing: 12
    width: 352

    // Thumbnail (clipboard images, screenshots) or an icon badge.
    Rectangle {
        id: thumb
        implicitWidth: root.image ? 64 : 44
        implicitHeight: 44
        radius: root.image ? 12 : 22
        color: Appearance.colors.colLayer2
        // clip is rectangular in Qt; mask to the rounded shape instead.
        layer.enabled: root.image !== ""
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: thumb.width
                height: thumb.height
                radius: thumb.radius
            }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            visible: !root.image
            text: root.p.icon ?? "info"
            iconSize: 24
            fill: 1
            color: root.accent
        }
        Image {
            anchors.fill: parent
            visible: root.image !== ""
            source: root.image === "" ? "" : (root.image.startsWith("/") ? "file://" + root.image : root.image)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 88
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        StyledText {
            Layout.fillWidth: true
            text: root.p.title ?? ""
            elide: Text.ElideRight
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.fillWidth: true
            text: root.p.body ?? ""
            visible: text.length > 0
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
    Repeater {
        model: (root.p.actions ?? []).slice(0, 2)
        IslandChip {
            required property var modelData
            required property int index
            text: modelData.text
            primary: index === 0
            accent: root.accent
            onClicked: {
                if ((modelData.command ?? []).length > 0)
                    Quickshell.execDetached(modelData.command);
                IslandState.dismiss(root.ev.id);
            }
        }
    }
    TapHandler {
        onTapped: IslandState.dismiss(root.ev.id)
    }
}

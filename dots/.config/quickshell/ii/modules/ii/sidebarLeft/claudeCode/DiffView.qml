pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

/**
 * Unified diff of a file change: {path, created?, hunks: [{header, lines}]},
 * lines prefixed with "+", "-" or " ".
 */
Rectangle {
    id: root
    property var diff
    readonly property color colAdded: ColorUtils.mix(Appearance.m3colors.term2, Appearance.colors.colLayer1, 0.25)
    readonly property color colRemoved: ColorUtils.mix(Appearance.m3colors.term1, Appearance.colors.colLayer1, 0.25)

    implicitHeight: column.implicitHeight + 6 * 2
    radius: Appearance.rounding.verysmall
    color: Appearance.colors.colLayer1
    clip: true

    readonly property var stats: {
        let add = 0, del = 0;
        for (const h of root.diff?.hunks ?? [])
            for (const l of h.lines) {
                if (l[0] === "+")
                    add++;
                else if (l[0] === "-")
                    del++;
            }
        return { add, del };
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 6
        }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            spacing: 6
            StyledText {
                Layout.fillWidth: true
                text: root.diff?.path ?? ""
                elide: Text.ElideMiddle
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: root.diff?.created ? "new" : `+${root.stats.add} -${root.stats.del}`
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        Repeater {
            model: root.diff?.hunks ?? []
            delegate: ColumnLayout {
                id: hunk
                required property var modelData
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    visible: hunk.modelData.header.length > 0
                    text: hunk.modelData.header
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
                Repeater {
                    model: hunk.modelData.lines
                    delegate: Rectangle {
                        id: line
                        required property string modelData
                        readonly property string sign: modelData.charAt(0)
                        Layout.fillWidth: true
                        implicitHeight: lineText.implicitHeight
                        color: sign === "+" ? root.colAdded : sign === "-" ? root.colRemoved : "transparent"
                        StyledText {
                            id: lineText
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            text: line.modelData.length > 0 ? line.modelData : " "
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: line.sign === " " ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }
}

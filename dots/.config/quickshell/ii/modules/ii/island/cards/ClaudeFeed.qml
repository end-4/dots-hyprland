import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island

// Small card under the island while hovering the Claude logo: the last tools it ran.
Rectangle {
    id: root
    width: 300
    height: col.implicitHeight + 20
    radius: 18
    color: Appearance.colors.colLayer1Base

    StyledRectangularShadow {
        target: root
        z: -1
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            spacing: 6
            Image {
                source: Qt.resolvedUrl("claude-logo.svg")
                sourceSize.width: 32
                sourceSize.height: 32
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
            }
            StyledText {
                Layout.fillWidth: true
                text: IslandState.waiting ? Translation.tr("Waiting for your answer") : Translation.tr("Recent activity")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
        }
        Repeater {
            model: IslandState.claudeFeed
            RowLayout {
                required property var modelData
                spacing: 6
                StyledText {
                    text: modelData.tool
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: "#d97757"
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 230
                    text: modelData.detail ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.monospace ?? "monospace"
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}

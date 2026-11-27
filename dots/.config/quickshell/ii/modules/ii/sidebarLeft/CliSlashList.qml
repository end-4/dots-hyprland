pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property var model: []
    property int selectedIndex: 0
    signal itemAccepted(var item)

    visible: (model?.length ?? 0) > 0
    implicitHeight: Math.min(220, listView.contentHeight + 12)
    clip: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    onModelChanged: selectedIndex = 0

    function moveUp() {
        selectedIndex = Math.max(0, selectedIndex - 1);
    }

    function moveDown() {
        selectedIndex = Math.min((model?.length ?? 1) - 1, selectedIndex + 1);
    }

    function currentItem() {
        if (!model || model.length === 0)
            return null;
        return model[selectedIndex] ?? model[0];
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        spacing: 2
        currentIndex: root.selectedIndex
        highlightFollowsCurrentItem: true
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        model: root.model

        delegate: RippleButton {
            id: rowBtn
            required property var modelData
            required property int index
            readonly property bool active: root.selectedIndex === index
            width: listView.width
            implicitHeight: 30
            buttonRadius: Appearance.rounding.small
            colBackground: active ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
            onHoveredChanged: if (hovered) root.selectedIndex = index
            onClicked: root.itemAccepted(modelData)

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.monospace
                    font.weight: Font.Medium
                    color: rowBtn.active ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                    text: modelData.displayName ?? modelData.name ?? ""
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: rowBtn.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignRight
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    text: modelData.count !== undefined
                        ? String(modelData.count)
                        : String(modelData.description ?? "").replace(/\n+/g, " · ")
                }
            }
        }
    }
}

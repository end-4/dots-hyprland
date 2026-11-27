pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    signal closeRequested()

    implicitHeight: Math.min(340, pickerCol.implicitHeight + 16)
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    readonly property string activeModelId: Ai.currentModelId ?? ""

    function familyContainsActive(fam): bool {
        if (fam.defaultId === root.activeModelId)
            return true;
        if (!fam.efforts)
            return false;
        for (let i = 0; i < fam.efforts.length; i++) {
            if (fam.efforts[i].id === root.activeModelId)
                return true;
        }
        return false;
    }

    function activeEffortIndex(fam): int {
        if (!fam.efforts || fam.efforts.length === 0)
            return 0;
        for (let i = 0; i < fam.efforts.length; i++) {
            if (fam.efforts[i].id === root.activeModelId)
                return i;
        }
        return 0;
    }

    ColumnLayout {
        id: pickerCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 2

            MaterialSymbol {
                text: "auto_awesome"
                iconSize: 16
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colSubtext
                text: Translation.tr("Antigravity Models")
            }
            RippleButton {
                implicitWidth: 26
                implicitHeight: 26
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                onClicked: Ai.refreshAgyModels()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ListView {
            id: familyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.min(265, contentHeight)
            clip: true
            spacing: 4
            model: Ai.agyFamilies

            delegate: Rectangle {
                id: famCard
                required property var modelData
                readonly property bool selected: root.familyContainsActive(modelData)
                readonly property bool hasEfforts: (modelData.efforts?.length ?? 0) > 1
                width: familyList.width
                implicitHeight: famCol.implicitHeight + 8
                radius: Appearance.rounding.small
                color: selected ? Appearance.colors.colPrimaryContainer : "transparent"

                ColumnLayout {
                    id: famCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    spacing: 4

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: famCard.selected ? "transparent" : Appearance.colors.colSurfaceContainerHigh
                        onClicked: {
                            Ai.setModel(famCard.modelData.defaultId, false);
                            if (!famCard.hasEfforts)
                                root.closeRequested();
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            MaterialSymbol {
                                text: famCard.hasEfforts ? "psychology" : "hub"
                                iconSize: 17
                                color: famCard.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: famCard.selected ? Font.Medium : Font.Normal
                                color: famCard.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                                text: famCard.modelData.name
                                elide: Text.ElideRight
                            }
                            MaterialSymbol {
                                visible: famCard.selected
                                text: "check"
                                iconSize: 17
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    // Horizontal thinking/effort slider for the selected model family
                    ColumnLayout {
                        visible: famCard.selected && famCard.hasEfforts
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.bottomMargin: 4
                        spacing: 2

                        Slider {
                            id: effortSlider
                            Layout.fillWidth: true
                            implicitHeight: 22
                            from: 0
                            to: Math.max(1, (famCard.modelData.efforts?.length ?? 1) - 1)
                            stepSize: 1
                            snapMode: Slider.SnapAlways
                            value: root.activeEffortIndex(famCard.modelData)
                            onMoved: {
                                const idx = Math.round(value);
                                const target = famCard.modelData.efforts[idx];
                                if (target)
                                    Ai.setModel(target.id, false);
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Repeater {
                                model: famCard.modelData.efforts ?? []
                                delegate: MouseArea {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: effortLbl.implicitHeight
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Ai.setModel(modelData.id, false)

                                    StyledText {
                                        id: effortLbl
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        font.pixelSize: Appearance.font.pixelSize.smaller - 1
                                        font.weight: modelData.id === root.activeModelId ? Font.DemiBold : Font.Normal
                                        color: modelData.id === root.activeModelId
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colOnPrimaryContainer
                                        opacity: modelData.id === root.activeModelId ? 1.0 : 0.7
                                        text: modelData.label
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

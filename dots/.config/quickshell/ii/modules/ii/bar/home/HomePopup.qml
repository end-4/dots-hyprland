import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.ii.bar

StyledPopup {
    id: root
    popupBackgroundMargin: 8

    readonly property var controlBlocks: [
        {
            "title": Translation.tr("Security & Access"),
            "icon": "shield_locked",
            "groups": ["locks", "covers"],
        },
        {
            "title": Translation.tr("Lighting"),
            "icon": "lightbulb",
            "groups": ["lights"],
        },
        {
            "title": Translation.tr("Climate & Appliances"),
            "icon": "tune",
            "groups": ["climate", "appliances"],
        },
    ]

    function entitiesForGroups(groupKeys) {
        const out = [];
        for (let i = 0; i < groupKeys.length; ++i) {
            const key = groupKeys[i];
            const entities = HomeAssistant.entitiesForGroup(key);
            for (let j = 0; j < entities.length; ++j) {
                out.push({
                    "groupKey": key,
                    "entity": entities[j],
                });
            }
        }
        return out;
    }

    function truncateName(name, maxChars) {
        const n = (name || "").trim();
        if (n.length <= maxChars) return n;
        return n.substring(0, Math.max(0, maxChars - 1)) + "…";
    }

    ColumnLayout {
        anchors.centerIn: parent
        implicitWidth: 760
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: "home"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: Translation.tr("Home")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: HomeAssistant.loading
                    ? Translation.tr("Refreshing…")
                    : Translation.tr("Last refresh: %1").arg(HomeAssistant.lastRefresh || "—")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        StyledText {
            visible: HomeAssistant.lastError.length > 0
            text: HomeAssistant.lastError
            color: Appearance.colors.colError
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Cameras row (HomeKit-style top area)
        ColumnLayout {
            visible: HomeAssistant.entitiesForGroup("cameras").length > 0
            Layout.fillWidth: true
            spacing: 6

            StyledText {
                text: HomeAssistant.groupMeta.cameras.title
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
            }

            RowLayout {
                spacing: 8

                Repeater {
                    model: HomeAssistant.entitiesForGroup("cameras")

                    delegate: Rectangle {
                        required property var modelData

                        readonly property var entity: modelData
                        readonly property string cameraUrl: HomeAssistant.cameraImageUrl(entity)

                        implicitWidth: 230
                        implicitHeight: 130
                        radius: Appearance.rounding.small
                        color: Appearance.m3colors.m3surface
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border

                        StyledImage {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: cameraUrl.length > 0
                            source: cameraUrl
                            fillMode: Image.PreserveAspectCrop
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 28
                            color: "#99000000"

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: HomeAssistant.entityName(entity)
                                color: "white"
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight
                                width: parent.width - 16
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: HomeAssistant.openCameraPip(parent.entity)
                        }
                    }
                }
            }
        }

        // Controls in 3 full-width blocks
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.controlBlocks

                delegate: Rectangle {
                    required property var modelData

                    readonly property var block: modelData
                    readonly property var rows: root.entitiesForGroups(block.groups)

                    visible: rows.length > 0
                    Layout.fillWidth: true
                    implicitHeight: contentCol.implicitHeight + 16
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainer
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        id: contentCol
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            MaterialSymbol {
                                text: block.icon
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                text: block.title
                                color: Appearance.colors.colOnSurfaceVariant
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 6
                            columnSpacing: 6
                            uniformCellWidths: true

                            Repeater {
                                model: rows

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property string groupKey: modelData.groupKey
                                    readonly property var entity: modelData.entity
                                    readonly property bool showDimmer: HomeAssistant.hasDimming(entity)

                                    Layout.fillWidth: true
                                    implicitWidth: 240
                                    implicitHeight: showDimmer ? 92 : 64
                                    radius: Appearance.rounding.normal
                                    color: Appearance.m3colors.m3surface
                                    border.width: 1
                                    border.color: Appearance.colors.colLayer0Border

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            MaterialSymbol {
                                                text: HomeAssistant.groupMeta[groupKey].icon
                                                iconSize: Appearance.font.pixelSize.large
                                                color: Appearance.colors.colOnSurfaceVariant
                                            }

                                            ColumnLayout {
                                                spacing: 2
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: root.truncateName(HomeAssistant.entityName(entity), 26)
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colOnSurfaceVariant
                                                    wrapMode: Text.NoWrap
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: HomeAssistant.stateLabel(entity)
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colSubtext
                                                    wrapMode: Text.NoWrap
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            RippleButton {
                                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                Layout.leftMargin: 2
                                                implicitWidth: 34
                                                implicitHeight: 34
                                                onClicked: HomeAssistant.toggleEntity(entity)

                                                contentItem: MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "power_settings_new"
                                                    iconSize: Appearance.font.pixelSize.normal
                                                    color: Appearance.colors.colOnPrimaryContainer
                                                }
                                            }
                                        }

                                        StyledSlider {
                                            id: dimmer
                                            visible: showDimmer
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 2
                                            Layout.rightMargin: 2
                                            configuration: StyledSlider.Configuration.S
                                            value: Math.max(0, Math.min(1, HomeAssistant.brightnessPct(entity) / 100))

                                            onMoved: {
                                                brightnessUpdate.pendingPct = Math.round(value * 100);
                                                brightnessUpdate.restart();
                                            }
                                        }

                                        Timer {
                                            id: brightnessUpdate
                                            property int pendingPct: 100
                                            interval: 180
                                            repeat: false
                                            onTriggered: HomeAssistant.setBrightnessPct(entity, pendingPct)
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
}

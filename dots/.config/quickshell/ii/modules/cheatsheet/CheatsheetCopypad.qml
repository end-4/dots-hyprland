pragma ComponentBehavior: Bound

import "copypad.js" as CPad
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
    id: root
    readonly property var cpstuff: CPad.padstuff
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2

    Row { // Copypad columns
        id: row
        spacing: root.spacing
        
        Repeater {
            model: cpstuff
            
            delegate: Column { // Copypad sections
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Repeater {
                    model: modelData

                    delegate: Item { // Section with real copypad entries
                        id: copypadSection
                        required property var modelData
                        implicitWidth: sectionColumn.implicitWidth
                        implicitHeight: sectionColumn.implicitHeight

                        Column {
                            id: sectionColumn
                            anchors.centerIn: parent
                            spacing: root.titleSpacing
                            
                            StyledText {
                                id: sectionTitle
                                font.family: Appearance.font.family.title
                                font.pixelSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer0
                                text: copypadSection.modelData.name
                            }

                            GridLayout {
                                id: copypadGrid
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                    model: {
                                        var result = [];
                                        for (var i = 0; i < copypadSection.modelData.entries.length; i++) {
                                            const cpEntry = copypadSection.modelData.entries[i];
                                            result.push({
                                                "type": "copy",
                                                "text": cpEntry,
                                            });
                                            result.push({
                                                "type": "entry",
                                                "text": cpEntry,
                                            });
                                        }
                                        return result;
                                    }
                                    delegate: Item {
                                        required property var modelData
                                        implicitWidth: copypadLoader.implicitWidth
                                        implicitHeight: copypadLoader.implicitHeight

                                        Loader {
                                            id: copypadLoader
                                            sourceComponent: (modelData.type === "copy") ? copyComponent : entryComponent
                                        }

                                        Component {
                                            id: copyComponent
                                            RippleButton {
                                                buttonRadius: Appearance.rounding.full
                                                contentItem: StyledText {
                                                    text: Translation.tr("Copy")
                                                }
                                                onClicked: {
                                                    Quickshell.execDetached(["wl-copy", modelData.text])
                                                }
                                            }
                                        }

                                        Component {
                                            id: entryComponent
                                            Item {
                                                id: entryItem
                                                implicitWidth: entryText.implicitWidth + 8 * 2
                                                implicitHeight: entryText.implicitHeight

                                                StyledText {
                                                    id: entryText
                                                    anchors.centerIn: parent
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    text: modelData.text
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
    }
    
}
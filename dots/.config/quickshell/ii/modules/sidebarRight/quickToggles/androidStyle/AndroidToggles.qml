import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

import "./androidStyle"


Rectangle { 
    id: toggleContainer
    property int containerVPadding: 10
    property int buttonPadding: 50
    implicitHeight: mainColumn.implicitHeight + containerVPadding  
    implicitWidth: 421 // fix? idk
    color: "transparent"
    radius: Appearance.rounding.normal

    ColumnLayout {
        spacing: 10
        id: mainColumn
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: root.rowModels
            delegate: ColumnLayout { 
                property string alignment: Config.options.quickToggles.android.align
                onAlignmentChanged: {
                    if (alignment === "left") Layout.alignment = Qt.AlignLeft
                    if (alignment === "right") Layout.alignment = Qt.AlignRight
                    if (alignment === "center") Layout.alignment = Qt.AlignCenter
                }
                ButtonGroup {
                    id: grid
                    
                    Repeater {
                        model: modelData
                        delegate: Loader {
                            sourceComponent:  QuickTogglesUtils.getComponentByName(modelData[1])
                            onLoaded: {
                                var optionIndex = root.getIndex.length
                                root.getIndex.push("0")
                                item.buttonSize = modelData[0]
                                item.buttonIndex = optionIndex
                                item.baseWidth = (toggleContainer.width - buttonPadding) / Config.options.quickToggles.android.columns * item.buttonSize
                            }
                        }
                    }
                }
            }
        }
    }
}

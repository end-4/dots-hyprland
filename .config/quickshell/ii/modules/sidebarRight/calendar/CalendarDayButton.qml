import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: button

    property string day
    property int isToday
    property bool bold
    property var taskList
    readonly property int taskMargin: 5

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38
    implicitHeight: 38
    toggled: (isToday == 1)
    buttonRadius: Appearance.rounding.small

    Rectangle {
        width: 6
        height: 6
        radius: 3
        color: (taskList.length > 0 && isToday !== -1 && !bold) ? Appearance.m3colors.m3primary : "transparent"
        anchors.top: parent.top
        anchors.left: parent.left
    }

    LazyLoader {
        id: dayPopUpLoader
        active: false
    
      
      PanelWindow {
            id: dayPopUp

            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:popup"
            WlrLayershell.layer: WlrLayer.Overlay
            implicitWidth: sidebarRoot.width
            implicitHeight: sidebarRoot.height
            property Rectangle dayPopRectProp: dayPopRect

              
        anchors {
            top: true
            right: true
            bottom: true
        }




        Rectangle {
                id: dayPopRect

                width: 240
                height: Math.min(columnLayout.implicitHeight + 2 * taskMargin, 1000)
                color: Appearance.m3colors.m3background
                radius: Appearance.rounding.small

                StyledFlickable {
                    id: styledFlicker

                    contentWidth: parent.width
                    contentHeight: columnLayout.implicitHeight

                    ColumnLayout {
                        id: columnLayout

                        width: parent.width - 2 * taskMargin
                        height: parent.height - 2 * taskMargin
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Repeater {

                            model: ScriptModel {
                                values: taskList.slice(0, 6) // limit shown elments to 6 since otherwiese it woul get to much
                            }

                            delegate: Rectangle {
                                width: parent.width
                                color: Appearance.colors.colLayer2
                                radius: Appearance.rounding.small
                                implicitHeight: contentColumn.implicitHeight

                                ColumnLayout {
                                    id: contentColumn

                                    width: parent.width
                                    spacing: 4
                                    Layout.margins: 10
                                    
                                    RowLayout {
                                        Layout.fillWidth: true

                                        StyledText {
                                        Layout.fillWidth: true // Needed for wrapping
                                        Layout.leftMargin: 10
                                        Layout.rightMargin: 10
                                        Layout.topMargin: 4
                                        text: modelData.content
                                        wrapMode: Text.Wrap
                                    }
                                          Rectangle {
                                            Layout.rightMargin: 10
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color:  modelData.color
                                          }
                                      }

                                    

                                    StyledText {
                                        Layout.fillWidth: true // Needed for wrapping
                                        Layout.leftMargin: 10
                                        Layout.rightMargin: 10
                                        Layout.topMargin: 4
                                                       
                                        text: (Qt.formatDateTime(modelData.startDate,  Config.options.time.format) !== Qt.formatDateTime(new Date(0, 0, 0, 0, 0, 0, 0),  Config.options.time.format) &&Qt.formatDateTime(modelData.endDate,  Config.options.time.format) !== Qt.formatDateTime(new Date(0, 0, 0, 23, 59, 0, 0),  Config.options.time.format) 
                                                ? Qt.formatDate(modelData.startDate, Config.options.time.longDateFormat)  + " : " + Qt.formatDateTime(modelData.startDate,  Config.options.time.format) + " - " + Qt.formatDateTime(modelData.endDate,  Config.options.time.format)
                                                : Qt.formatDate(modelData.startDate, Config.options.time.longDateFormat) )


                                        color: Appearance.m3colors.m3outline
                                        wrapMode: Text.Wrap
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Item {
                                            Layout.fillWidth: true
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

    contentItem: StyledText {
        anchors.fill: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.DemiBold : Font.Normal
        color: (isToday == 1) ? Appearance.m3colors.m3onPrimary : (isToday == 0) ? Appearance.colors.colOnLayer1 : Appearance.colors.colOutlineVariant

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
              if  (button.taskList.length > 0 && button.isToday !== -1 && !button.bold) {
                    dayPopUpLoader.active = true;
                    const dayPopUp = dayPopUpLoader.item
                    const dayPopRect = dayPopUp.dayPopRectProp
                    const globalPos = dayPopUp.QsWindow?.mapFromItem(button, 0 , 0);
                    dayPopRect.x =globalPos.x - dayPopRect.width/2;
                    dayPopRect.y = globalPos.y + button.height  - dayPopRect.height 
                }
            }
            onExited: dayPopUpLoader.active  = false
        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }

}

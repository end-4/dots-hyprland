import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: btnRoot
    
    property string icon: ""
    property string text: ""
    property bool highlighted: false
    property string customColor: "" 
    
    signal clicked()

    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: 36
    
    radius: 8
    color: mouseArea.containsMouse ? "#505050" : "#333333"
    border.width: 1
    border.color: highlighted ? Appearance.colors.colPrimary : "#555555"

    Behavior on color { ColorAnimation { duration: 100 } }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Appearance.colors.colPrimary
        opacity: 0.2
        visible: btnRoot.highlighted
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: btnRoot.text !== "" ? 8 : 0
        
        MaterialSymbol {
            visible: btnRoot.icon !== ""
            text: btnRoot.icon
            iconSize: 18
            color: btnRoot.customColor !== "" 
                   ? btnRoot.customColor 
                   : (btnRoot.highlighted ? Appearance.colors.colPrimary : "#FFFFFF")
        }
        
        Label {
            visible: btnRoot.text !== ""
            text: btnRoot.text
            color: btnRoot.customColor !== "" 
                   ? btnRoot.customColor 
                   : (btnRoot.highlighted ? Appearance.colors.colPrimary : "#FFFFFF")
            font.bold: true
            font.pixelSize: 14
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btnRoot.clicked()
    }
}
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models as Models
import qs.modules.ii.overlay
import qs.services

StyledOverlayWidget {
    id: root
    resizable: false

    Component.onCompleted: {
        // Force reset size to content size to fix large box issue
        root.persistentStateEntry.width = 0
        root.persistentStateEntry.height = 0
    }

    contentItem: RowLayout {
        id: display
        spacing: 8
        
        property int sourceIndex: 0
        property string basePath: Quickshell.shellPath("assets/icons/catwalk/" + (Appearance.m3colors.darkmode ? "" : "black/"))
        property string currentIcon: basePath + "my-idle-0-symbolic.svg"
        property real cpuUsage: ResourceUsage.cpuUsage * 100 // 0-100
        property real idleThreshold: 10 
        property int idleFrameCount: 4
        property int activeFrameCount: 5
        
        Image {
            id: catImage
            Layout.preferredHeight: 60
            Layout.preferredWidth: 60
            Layout.alignment: Qt.AlignVCenter
            source: display.currentIcon
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
        }
        
        Timer {
            id: animTimer
            running: root.visible
            repeat: true
            // interval: 5000 / Math.sqrt(totalSensor.value + 35) - 400
            interval: Math.max(50, Math.ceil(5000 / Math.sqrt(display.cpuUsage + 35) - 400))
            onTriggered: {
                if (display.cpuUsage < display.idleThreshold) {
                    if (display.sourceIndex >= display.idleFrameCount) display.sourceIndex = 0
                    display.currentIcon = display.basePath + "my-idle-" + display.sourceIndex + "-symbolic.svg"
                } else {
                    if (display.sourceIndex >= display.activeFrameCount) display.sourceIndex = 0
                    display.currentIcon = display.basePath + "my-active-" + display.sourceIndex + "-symbolic.svg"
                }
                display.sourceIndex++
            }
        }
        
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: display.cpuUsage.toFixed(1) + "%"
            font.pixelSize: 32
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer0
            style: Text.Outline
            styleColor: Appearance.colors.colLayer0
        }
    }
}

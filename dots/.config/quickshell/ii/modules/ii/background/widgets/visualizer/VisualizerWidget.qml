import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

PinnedWidget {
    id: root
    
    configEntryName: "visualizer"

    property list<real> points: []
    property color primaryColor: Appearance.colors.colPrimary
    
    property int targetHeight: configEntry?.height ?? 200
    property int targetBarWidth: configEntry?.targetBarWidth ?? 50
    property int barSpacing: configEntry?.barSpacing ?? 5
    property real barRounding: configEntry?.barRounding ?? 0.4
    property real smoothing: configEntry?.smoothing ?? 1.0
    property real visualOpacity: configEntry?.opacity ?? 1.0
    property bool isMono: configEntry?.mono ?? true
    property bool shown: false

    height: targetHeight
    
    opacity: (shown && baseVisibility) ? 1 : 0
    visible: opacity > 0
    
    Behavior on opacity {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    readonly property int barCount: Math.max(1, Math.floor(width / (targetBarWidth + barSpacing)))
    readonly property real exactWidth: (width - (barSpacing * (barCount - 1))) / barCount

    property real activityOpacity: 0
    Behavior on activityOpacity {
        NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
    }

    readonly property var processedPoints: {
        let raw = points;
        if (!raw || raw.length === 0) return Array(barCount).fill(0);
        let mapped = new Array(barCount);
        for (let i = 0; i < barCount; i++) {
            let relPos = isMono 
                ? (Math.abs(i - (barCount - 1) / 2) / ((barCount - 1) / 2 || 1)) * (raw.length - 1)
                : (i / (barCount - 1 || 1)) * (raw.length - 1);

            let low = Math.floor(relPos), high = Math.ceil(relPos), mix = relPos - low;
            mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * mix);
        }
        return mapped;
    }

    Timer {
        id: silenceTimer
        interval: 1000
        onTriggered: root.activityOpacity = 0
    }

    onPointsChanged: {
        // Only trigger if points actually exist and aren't all zero
        if (points.length > 0 && points.some(p => p > 0)) {
            root.activityOpacity = 1.0;
            silenceTimer.restart();
        }
    }

    Row {
        anchors.fill: parent
        spacing: root.barSpacing
        
        Repeater {
            model: root.barCount
            delegate: Rectangle {
                readonly property real val: root.processedPoints[index] || 0
                width: root.exactWidth
                height: Math.max(2, (val / 1000) * root.height)
                anchors.bottom: parent.bottom
                radius: width * root.barRounding
                opacity: root.visualOpacity * root.activityOpacity
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: CF.ColorUtils.transparentize(root.primaryColor, 0.1) }
                    GradientStop { position: 1.0; color: root.primaryColor }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: root.smoothing * 100
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}
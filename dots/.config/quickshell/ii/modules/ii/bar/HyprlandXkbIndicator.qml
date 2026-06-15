import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    active: HyprlandXkb.layoutCodes.length > 1
    visible: active

    function abbreviateLayoutCode(fullCode) {
        return fullCode.split(':').map(layout => {
            const baseLayout = layout.split('-')[0];
            return baseLayout.slice(0, 4);
        }).join('\n');
    }

    sourceComponent: Item {
        implicitWidth: root.vertical ? null : layoutCodeText.implicitWidth
        implicitHeight: root.vertical ? layoutCodeText.implicitHeight : null

        StyledText {
            id: layoutCodeText
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: abbreviateLayoutCode(HyprlandXkb.currentLayoutCode)
            font.pixelSize: text.includes("\n") ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.small
            color: root.color
            animateChange: false
            transformOrigin: Item.Center

            transform: Translate {
                id: textTranslate
            }

            onTextChanged: {
                popAnim.restart();
            }

            ParallelAnimation {
                id: popAnim
                NumberAnimation {
                    target: layoutCodeText
                    property: "scale"
                    from: 0.6
                    to: 1.0
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                }
                NumberAnimation {
                    target: textTranslate
                    property: "y"
                    from: root.vertical ? 12 : -12
                    to: 0
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                }
                NumberAnimation {
                    target: layoutCodeText
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}

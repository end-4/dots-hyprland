import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.modules.common
import qs.modules.common.widgets.shapes
import "shapes/geometry/offset.js" as Offset
import "shapes/shapes/corner-rounding.js" as CornerRounding
import "shapes/shapes/rounded-polygon.js" as RoundedPolygon
import "shapes/material-shapes.js" as MaterialShapes

Item {
    id: root
    property int sides: 12  
    property int implicitSize: 100
    property alias color: shapeCanvas.color

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property var cornerRounding: new CornerRounding.CornerRounding((sides < 17 ? 1.5 : 1.1) / Math.max(sides, 1))

    ShapeCanvas {
        id: shapeCanvas
        anchors.fill: parent
        roundedPolygon: switch(sides) {
            case 0: return MaterialShapes.getCircle();
            case 1: return MaterialShapes.getCircle();
            case 4: return MaterialShapes.getCookie4Sided();
            case 6: return MaterialShapes.getCookie6Sided();
            case 7: return MaterialShapes.getCookie7Sided();
            case 9: return MaterialShapes.getCookie9Sided();
            case 12: return MaterialShapes.getCookie12Sided();
            default: return RoundedPolygon.RoundedPolygon.star(sides, 1, 0.8, root.cornerRounding)
                .transformed((x, y) => MaterialShapes.rotate30.map(new Offset.Offset(x, y)))
                .normalized();
        }
    }
}


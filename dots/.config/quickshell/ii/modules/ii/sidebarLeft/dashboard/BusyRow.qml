import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Spinner + texto mientras una accion esta en curso.
Row {
    id: root
    property string label
    spacing: 8
    MaterialSymbol {
        id: spinner
        text: "progress_activity"
        iconSize: 18
        color: Appearance.m3colors.m3primary
        RotationAnimator on rotation {
            from: 0; to: 360; duration: 1000
            loops: Animation.Infinite
            running: spinner.visible
        }
    }
    StyledText {
        anchors.verticalCenter: spinner.verticalCenter
        text: root.label
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.small
    }
}

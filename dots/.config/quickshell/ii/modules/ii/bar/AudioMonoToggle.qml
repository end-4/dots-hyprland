pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Bar indicator that toggles the PipeWire output between stereo and a runtime
 * mono downmix. Left-click runs scripts/audio-mono-toggle.sh; the icon state is
 * derived reactively from the current default sink (no polling) — mono is active
 * while the default sink is the temporary "mono_sink" node created by the script.
 */
MouseArea {
    id: root

    readonly property bool isMono: (Audio.sink?.name ?? "") === "mono_sink"
    property color colNormal: Appearance.colors.colOnLayer0
    property color colActive: Appearance.colors.colPrimary

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    onPressed: event => {
        if (event.button === Qt.LeftButton) {
            Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/audio-mono-toggle.sh"), "toggle"]);
        }
        event.accepted = true;
    }

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: root.isMono ? "speaker" : "speaker_group"
        iconSize: Appearance.font.pixelSize.larger
        fill: root.isMono ? 1 : 0
        color: root.isMono ? root.colActive : root.colNormal

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    PopupToolTip {
        id: tooltip
        text: root.isMono
            ? Translation.tr("Audio output: Mono — click to switch to stereo")
            : Translation.tr("Audio output: Stereo — click to switch to mono")
        extraVisibleCondition: root.containsMouse
        alternativeVisibleCondition: extraVisibleCondition
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }
}

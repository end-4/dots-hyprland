import qs.services
import qs.modules.common.widgets
import QtQuick
import Quickshell

/**
 * Copies text and confirms by holding a checked icon for a moment.
 */
AiMessageControlButton {
    id: root
    property string copyText: ""
    property string tooltipText: Translation.tr("Copy")

    buttonIcon: activated ? "inventory" : "content_copy"
    onClicked: {
        Quickshell.clipboardText = root.copyText;
        root.confirm();
    }

    StyledToolTip {
        text: root.tooltipText
    }
}

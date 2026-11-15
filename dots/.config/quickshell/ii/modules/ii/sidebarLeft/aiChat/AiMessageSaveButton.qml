import qs.services
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell

/**
 * Writes text to a file in Downloads, names it in a notification, and confirms on the button.
 */
AiMessageControlButton {
    id: root
    property string saveText: ""
    property string fileName: "file.txt"
    property string notificationTitle: Translation.tr("Saved to file")
    property string tooltipText: Translation.tr("Save to Downloads")

    buttonIcon: activated ? "check" : "save"
    onClicked: {
        const target = `${FileUtils.trimFileProtocol(Directories.downloads)}/${root.fileName}`;
        Quickshell.execDetached(["bash", "-c",
            `echo '${StringUtils.shellSingleQuoteEscape(root.saveText)}' > '${StringUtils.shellSingleQuoteEscape(target)}'`
        ]);
        Quickshell.execDetached(["notify-send",
            root.notificationTitle,
            Translation.tr("Saved to %1").arg(target),
            "-a", "Shell"
        ]);
        root.confirm();
    }

    StyledToolTip {
        text: root.tooltipText
    }
}

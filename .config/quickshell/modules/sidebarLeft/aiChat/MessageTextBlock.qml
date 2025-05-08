pragma ComponentBehavior: Bound

import "root:/"
import "root:/services"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "../"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

TextArea {
    // These are needed on the parent loader
    property bool editing: parent?.editing ?? false
    property bool renderMarkdown: parent?.renderMarkdown ?? true
    property bool enableMouseSelection: parent?.enableMouseSelection ?? false
    property var segment: parent?.segment ?? {}
    property var messageData: parent?.messageData ?? {}

    Layout.fillWidth: true
    readOnly: !editing
    selectByMouse: enableMouseSelection || editing
    renderType: Text.NativeRendering
    font.family: Appearance.font.family.reading
    font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
    font.pixelSize: Appearance.font.pixelSize.small
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.m3colors.m3secondaryContainer
    wrapMode: TextEdit.Wrap
    color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
    textFormat: renderMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
    text: messageData.thinking ? qsTr("Waiting for response...") : segment.content

    onTextChanged: {
        segment.content = text
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_C) && event.modifiers == Qt.ControlModifier) {
            messageText.copy()
            event.accepted = true
        }
    }

    onLinkActivated: (link) => {
        Qt.openUrlExternally(link)
        Hyprland.dispatch("global quickshell:sidebarLeftClose")
    }

    MouseArea { // Pointing hand for links
        anchors.fill: parent
        acceptedButtons: Qt.NoButton // Only for hover
        hoverEnabled: true
        cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : 
            (enableMouseSelection || editing) ? Qt.IBeamCursor : Qt.ArrowCursor
    }
}

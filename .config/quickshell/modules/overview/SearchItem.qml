// pragma NativeMethodBehavior: AcceptThisObject
import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

RippleButton {
    id: root
    property var entry
    property string query
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type
    property string itemName: entry?.name
    property string itemIcon: entry?.icon ?? ""
    property var itemExecute: entry?.execute
    property string fontType: entry?.fontType ?? "main"
    property string itemClickActionName: entry?.clickActionName
    property string materialSymbol: entry?.materialSymbol ?? ""

    property string highlightPrefix: `<b><font color="${Appearance.m3colors.m3primary}">`
    property string highlightSuffix: `</font></b>`
    function highlightContent(content, query) {
        if (!query || query.length === 0 || content == query || fontType === "monospace")
            return StringUtils.escapeHtml(content);

        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();

        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                // Add non-highlighted part (escaped)
                if (i > lastIndex)
                    result += StringUtils.escapeHtml(content.slice(lastIndex, i));
                // Add highlighted character (escaped)
                result += root.highlightPrefix + StringUtils.escapeHtml(content[i]) + root.highlightSuffix;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        // Add the rest of the string (escaped)
        if (lastIndex < content.length)
            result += StringUtils.escapeHtml(content.slice(lastIndex));

        return result;
    }

    property string displayContent: highlightContent(root.itemName, root.query)
    
    visible: root.entryShown
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int buttonVerticalPadding: 5
    property bool keyboardDown: false

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: rowLayout.implicitHeight + root.buttonVerticalPadding * 2
    implicitWidth: rowLayout.implicitWidth + root.buttonHorizontalPadding * 2
    buttonRadius: Appearance.rounding.normal
    colBackground: (root.down || root.keyboardDown) ? Appearance.colors.colLayer1Active : 
        ((root.hovered || root.focus) ? Appearance.colors.colLayer1Hover : 
        ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 1))
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

    background {
        anchors.fill: root
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
    }

    PointingHandInteraction {}
    onClicked: {
        root.itemExecute()
        Hyprland.dispatch("global quickshell:overviewClose")
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = true
            root.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = false
            event.accepted = true;
        }
    }

    RowLayout {
        id: rowLayout
        spacing: iconLoader.sourceComponent === null ? 0 : 10
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin + root.buttonHorizontalPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonHorizontalPadding

        // Icon
        Loader {
            id: iconLoader
            active: true
            sourceComponent: root.materialSymbol !== "" ? materialSymbolComponent :
                root.itemIcon !== "" ? iconImageComponent : 
                null
        }

        Component {
            id: iconImageComponent
            IconImage {
                source: Quickshell.iconPath(root.itemIcon, "image-missing")
                width: 35
                height: 35
            }
        }

        Component {
            id: materialSymbolComponent
            MaterialSymbol {
                text: root.materialSymbol
                iconSize: 30
                color: Appearance.m3colors.m3onSurface
            }
        }

        // Main text
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                visible: root.itemType && root.itemType != qsTr("App")
                text: root.itemType
            }
            StyledText {
                Layout.fillWidth: true
                id: nameText
                textFormat: Text.StyledText // RichText also works, but StyledText ensures elide work
                font.pixelSize: Appearance.font.pixelSize.normal
                font.family: Appearance.font.family[root.fontType]
                color: Appearance.m3colors.m3onSurface
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: `${root.displayContent}`
            }
        }

        // Action text
        StyledText {
            Layout.fillWidth: false
            visible: (root.hovered || root.focus)
            id: clickAction
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            horizontalAlignment: Text.AlignRight
            text: root.itemClickActionName
        }
    }
}
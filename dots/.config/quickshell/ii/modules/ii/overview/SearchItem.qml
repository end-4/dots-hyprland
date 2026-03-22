// pragma NativeMethodBehavior: AcceptThisObject
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

RippleButton {
    id: root
    property LauncherSearchResult entry
    property string query
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type ?? Translation.tr("App")
    property string itemName: entry?.name ?? ""
    property var iconType: entry?.iconType
    property string iconName: entry?.iconName ?? ""
    property var itemExecute: entry?.execute
    property var fontType: switch(entry?.fontType) {
        case LauncherSearchResult.FontType.Monospace:
            return "monospace"
        case LauncherSearchResult.FontType.Normal:
            return "main"
        default:
            return "main"
    }
    property string itemClickActionName: entry?.verb ?? "Open"
    property string bigText: entry?.iconType === LauncherSearchResult.IconType.Text ? entry?.iconName ?? "" : ""
    property string materialSymbol: entry.iconType === LauncherSearchResult.IconType.Material ? entry?.iconName ?? "" : ""
    property string itemComment: entry?.comment ?? ""
    property string itemGenericName: entry?.genericName ?? ""
    property string appDescription: {
        const comment = (root.itemComment || "").trim();
        if (comment.length > 0)
            return comment;
        return (root.itemGenericName || "").trim();
    }
    property string cliphistRawString: entry?.rawValue ?? ""
    property bool blurImage: entry?.blurImage ?? false
    
    visible: root.entryShown
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int buttonVerticalPadding: 7
    property bool keyboardDown: false

    implicitHeight: Math.max(
        rowLayout.implicitHeight + root.buttonVerticalPadding * 2,
        root.isAppEntry ? 58 : 0
    )
    implicitWidth: rowLayout.implicitWidth + root.buttonHorizontalPadding * 2
    buttonRadius: Appearance.rounding.normal
    colBackground: (root.down || root.keyboardDown) ? Appearance.colors.colPrimaryContainerActive : 
        ((root.hovered || root.focus) ? Appearance.colors.colPrimaryContainer : 
        ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1))
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple: Appearance.colors.colPrimaryContainerActive

    property string highlightPrefix: `<u><font color="${Appearance.colors.colPrimary}">`
    property string highlightSuffix: `</font></u>`
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

    property list<string> urls: {
        if (!root.itemName) return [];
        // Regular expression to match URLs
        const urlRegex = /https?:\/\/[^\s<>"{}|\\^`[\]]+/gi;
        const matches = root.itemName?.match(urlRegex)
            ?.filter(url => !url.includes("…")) // Elided = invalid
        return matches ? matches : [];
    }
    
    PointingHandInteraction {}

    property bool isAppEntry: root.entry && (root.itemType === Translation.tr("App")) && (root.entry.id || "").length > 0
    property bool showUninstallButton: Config?.options?.launcher?.showUninstallButton ?? true

    background {
        anchors.fill: root
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
    }

    onClicked: {
        GlobalStates.overviewOpen = false
        root.itemExecute()
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Delete && event.modifiers === Qt.ShiftModifier) {
            const deleteAction = root.entry.actions.find(action => action.name == Translation.tr("Delete"));

            if (deleteAction) {
                deleteAction.execute()
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
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
            sourceComponent: switch(root.iconType) {
                case LauncherSearchResult.IconType.Material:
                    return materialSymbolComponent
                case LauncherSearchResult.IconType.Text:
                    return bigTextComponent
                case LauncherSearchResult.IconType.System:
                    return iconImageComponent
                case LauncherSearchResult.IconType.None:
                    return null
                default:
                    return null
            }
        }

        Component {
            id: iconImageComponent
            IconImage {
                source: Quickshell.iconPath(root.iconName, "image-missing")
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

        Component {
            id: bigTextComponent
            StyledText {
                text: root.bigText
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.m3colors.m3onSurface
            }
        }

        // Main text
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                visible: root.itemType && root.itemType != Translation.tr("App")
                text: root.itemType
            }
            RowLayout {
                Loader { // Checkmark for copied clipboard entry
                    visible: itemName == Quickshell.clipboardText && root.cliphistRawString
                    active: itemName == Quickshell.clipboardText && root.cliphistRawString
                    sourceComponent: Rectangle {
                        implicitWidth: activeText.implicitHeight
                        implicitHeight: activeText.implicitHeight
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary
                        MaterialSymbol {
                            id: activeText
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }
                Repeater { // Favicons for links
                    model: root.query == root.itemName ? [] : root.urls
                    Favicon {
                        required property var modelData
                        size: parent.height
                        url: modelData
                    }
                }
                StyledText { // Item name/content
                    Layout.fillWidth: true
                    id: nameText
                    textFormat: Text.StyledText // RichText also works, but StyledText ensures elide work
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family[root.fontType]
                    color: Appearance.m3colors.m3onSurface
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    text: `${root.displayContent}`
                }
            }
            StyledText { // App description/subtitle
                Layout.fillWidth: true
                visible: root.itemType === Translation.tr("App") && root.appDescription.length > 0
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 1
                text: root.appDescription
            }
            Loader { // Clipboard image preview
                active: root.cliphistRawString && Cliphist.entryIsImage(root.cliphistRawString)
                sourceComponent: CliphistImage {
                    Layout.fillWidth: true
                    entry: root.cliphistRawString
                    maxWidth: contentColumn.width
                    maxHeight: 140
                    blur: root.blurImage
                }
            }
        }

        // Action text (Open)
        StyledText {
            Layout.fillWidth: false
            visible: (root.hovered || root.focus)
            id: clickAction
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnPrimaryContainer
            horizontalAlignment: Text.AlignRight
            text: root.itemClickActionName
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            // Uninstall (app entries only; aligned with other secondary action buttons)
            RippleButton {
                id: uninstallButton
                visible: root.showUninstallButton && root.isAppEntry && (root.hovered || root.focus)
                implicitWidth: 34
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1)
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                colRipple: Appearance.colors.colSurfaceContainerHigh
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    iconSize: 20
                    color: uninstallButton.hovered ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
                }
                onClicked: uninstallConfirmPopup.open()
                StyledToolTip {
                    text: Translation.tr("Uninstall")
                }
            }
            Repeater {
                model: (root.entry.actions ?? []).slice(0, 4)
                delegate: RippleButton {
                    id: actionButton
                    required property var modelData
                    property var iconType: modelData.iconType
                    property string iconName: modelData.iconName ?? ""
                    implicitHeight: 34
                    implicitWidth: 34

                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive

                    contentItem: Item {
                        id: actionContentItem
                        anchors.centerIn: parent
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.iconType === LauncherSearchResult.IconType.Material || actionButton.iconName === ""
                            sourceComponent: MaterialSymbol {
                                text: actionButton.iconName || "video_settings"
                                font.pixelSize: Appearance.font.pixelSize.hugeass
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.iconType === LauncherSearchResult.IconType.System && actionButton.iconName !== ""
                            sourceComponent: IconImage {
                                source: Quickshell.iconPath(actionButton.iconName)
                                implicitSize: 20
                            }
                        }
                    }

                    onClicked: modelData.execute()

                    StyledToolTip {
                        text: modelData.name
                    }
                }
            }
        }

    // Uninstall confirmation (themed, animated, centered on screen)
    property var popupContainer: root.Window?.window?.contentItem ?? root
    Popup {
        id: uninstallConfirmPopup
        parent: popupContainer
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        width: 360
        padding: 0
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20

        background: Item {
            opacity: uninstallConfirmPopup.visible ? 1 : 0
            scale: uninstallConfirmPopup.visible ? 1 : 0.92
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
            StyledRectangularShadow { target: confirmBg }
            Rectangle {
                id: confirmBg
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: Appearance.colors.colBackgroundSurfaceContainer
            }
        }

        contentItem: Item {
            opacity: uninstallConfirmPopup.visible ? 1 : 0
            scale: uninstallConfirmPopup.visible ? 1 : 0.92
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSurface
                    text: Translation.tr("Are you sure you want to uninstall %1?").arg(root.itemName || root.entry?.id || "")
                }
                RowLayout {
                    Layout.topMargin: 8
                    spacing: 12
                    Layout.alignment: Qt.AlignRight
                RippleButton {
                    buttonText: Translation.tr("Cancel")
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1)
                    colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                    colRipple: Appearance.colors.colSurfaceContainerHigh
                    contentItem: Item {
                        anchors.fill: parent
                        StyledText {
                            anchors.centerIn: parent
                            text: parent.parent.buttonText
                            color: Appearance.colors.colOnSurface
                        }
                    }
                    onClicked: uninstallConfirmPopup.close()
                }
                RippleButton {
                    buttonText: Translation.tr("Uninstall")
                    implicitWidth: 110
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive
                    contentItem: Item {
                        anchors.fill: parent
                        StyledText {
                            anchors.centerIn: parent
                            text: parent.parent.buttonText
                            color: Appearance.colors.colOnErrorContainer
                        }
                    }
                    onClicked: {
                        LauncherApps.uninstallApp(root.entry?.id ?? "");
                        uninstallConfirmPopup.close();
                    }
                }
            }
            }
        }
        }
    }
}

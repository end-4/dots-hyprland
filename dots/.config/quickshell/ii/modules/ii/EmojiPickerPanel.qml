pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Emoji Picker panel.
 * Fuzzy-search through the emoji list. Clicking copies to clipboard
 * and optionally types it via Ydotool.
 */
Item {
    id: root
    implicitWidth: 340
    implicitHeight: Math.min(450, searchBox.implicitHeight + 12 + grid.implicitHeight + 12)

    readonly property var emojiResults: {
        const q = searchInput.text.trim()
        if (q.length === 0) return Emojis.list
        return Emojis.fuzzyQuery(q)
    }

    property string lastCopied: ""

    Component.onCompleted: Emojis.load()

    ColumnLayout {
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8

        // ── Search bar ────────────────────────────────────────────────────
        Item {
            id: searchBox
            Layout.fillWidth: true
            implicitHeight: searchRow.implicitHeight

            RowLayout {
                id: searchRow
                anchors.fill: parent
                spacing: 8

                MaterialSymbol {
                    text: "search"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }

                MaterialTextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search emoji…")
                    focus: true
                    onTextChanged: {
                        root.lastCopied = ""
                    }
                }

                // Clear button
                RippleButton {
                    visible: searchInput.text.length > 0
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    onClicked: searchInput.text = ""
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 14
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        // ── Copied confirmation ───────────────────────────────────────────
        StyledText {
            visible: root.lastCopied.length > 0
            text: root.lastCopied + "  " + Translation.tr("Copied!")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colPrimary
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // ── Result count ──────────────────────────────────────────────────
        StyledText {
            text: Translation.tr("%1 emojis").arg(root.emojiResults.length)
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colSubtext
            visible: searchInput.text.trim().length > 0
            Layout.fillWidth: true
        }

        // ── Emoji grid ────────────────────────────────────────────────────
        Item {
            id: grid
            Layout.fillWidth: true
            implicitHeight: Math.min(emojiGrid.contentHeight, 340)

            GridView {
                id: emojiGrid
                anchors.fill: parent
                clip: true
                cellWidth: 44
                cellHeight: 44
                model: root.emojiResults
                ScrollBar.vertical: StyledScrollBar {}

                delegate: EmojiDelegate {
                    required property var modelData
                    width: emojiGrid.cellWidth
                    height: emojiGrid.cellHeight
                    emojiText: modelData
                    onCopyRequested: emoji => {
                        Quickshell.clipboardText = emoji
                        root.lastCopied = emoji
                        // Also type it if Ydotool is available
                        Ydotool.type(emoji)
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────
        PagePlaceholder {
            visible: root.emojiResults.length === 0 && Emojis.list.length > 0
            Layout.fillWidth: true
            icon: "sentiment_dissatisfied"
            text: Translation.tr("No emojis found")
            subtext: Translation.tr("Try a different search term")
        }

        PagePlaceholder {
            visible: Emojis.list.length === 0
            Layout.fillWidth: true
            icon: "hourglass_empty"
            text: Translation.tr("Loading emojis…")
            subtext: Translation.tr("The emoji list is being prepared")
        }
    }

    // ── Emoji button delegate ─────────────────────────────────────────────
    component EmojiDelegate: Item {
        required property string emojiText
        signal copyRequested(string emoji)

        RippleButton {
            anchors.fill: parent
            anchors.margins: 2
            buttonRadius: Appearance.rounding.small
            onClicked: parent.copyRequested(parent.emojiText)
            contentItem: StyledText {
                anchors.centerIn: parent
                text: parent.parent.emojiText
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
            }
            StyledToolTip {
                text: parent.parent.emojiText
            }
        }
    }
}

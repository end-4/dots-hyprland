import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * Popup dialog for configuring Wallhaven search filters.
 * Used within the wallpaper selector when Wallhaven mode is active.
 */
WindowDialog {
    id: root
    backgroundWidth: 460

    // Force hide on startup
    Component.onCompleted: {
        show = false
    }

    function triggerSearch() {
        WallhavenSearch.saveToConfig()
        WallhavenSearch.search(WallhavenSearch.currentQuery, 1)
    }

    WindowDialogTitle {
        text: Translation.tr("Wallhaven Settings")
    }

    WindowDialogSeparator {}

    // API Key
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            text: Translation.tr("API Key")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        TextField {
            id: apiKeyField
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: Translation.tr("Optional — needed for NSFW")
            placeholderTextColor: Appearance.colors.colSubtext
            color: Appearance.colors.colOnLayer1
            text: WallhavenSearch.apiKey
            font {
                family: Appearance.font.family.main
                pixelSize: Appearance.font.pixelSize.small
                hintingPreference: Font.PreferFullHinting
            }
            renderType: Text.NativeRendering
            background: Rectangle {
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small
                border.width: 1
                border.color: apiKeyField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
            }
            onEditingFinished: {
                WallhavenSearch.apiKey = text
                WallhavenSearch.saveToConfig()
            }
        }
    }

    WindowDialogSeparator {}

    // Sorting
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledText {
            text: Translation.tr("Sort by")
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.preferredWidth: 80
        }

        StyledComboBox {
            id: sortingCombo
            Layout.fillWidth: true
            model: [
                Translation.tr("Date Added"),
                Translation.tr("Relevance"),
                Translation.tr("Random"),
                Translation.tr("Views"),
                Translation.tr("Favorites"),
                Translation.tr("Top List"),
            ]
            property var sortKeys: ["date_added", "relevance", "random", "views", "favorites", "toplist"]
            currentIndex: sortKeys.indexOf(WallhavenSearch.sorting)
            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    WallhavenSearch.sorting = sortKeys[currentIndex]
                    root.triggerSearch()
                }
            }
        }
    }

    // Order
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: sortingCombo.currentIndex !== 2 // Hide for "random"

        StyledText {
            text: Translation.tr("Order")
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.preferredWidth: 80
        }

        StyledComboBox {
            Layout.fillWidth: true
            model: [Translation.tr("Descending"), Translation.tr("Ascending")]
            property var orderKeys: ["desc", "asc"]
            currentIndex: orderKeys.indexOf(WallhavenSearch.order)
            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    WallhavenSearch.order = orderKeys[currentIndex]
                    root.triggerSearch()
                }
            }
        }
    }

    WindowDialogSeparator {}

    // Categories
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledText {
            text: Translation.tr("Categories")
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.preferredWidth: 80
        }

        RowLayout {
            spacing: 12

            RippleButton {
                implicitWidth: implicitHeight * 2.5
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.categories.charAt(0) === "1"
                colBackgroundToggled: Appearance.colors.colPrimary
                onClicked: {
                    var cats = WallhavenSearch.categories
                    WallhavenSearch.categories = (cats.charAt(0) === "1" ? "0" : "1") + cats.charAt(1) + cats.charAt(2)
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: Translation.tr("General")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                implicitWidth: implicitHeight * 2.5
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.categories.charAt(1) === "1"
                colBackgroundToggled: Appearance.colors.colPrimary
                onClicked: {
                    var cats = WallhavenSearch.categories
                    WallhavenSearch.categories = cats.charAt(0) + (cats.charAt(1) === "1" ? "0" : "1") + cats.charAt(2)
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: Translation.tr("Anime")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                implicitWidth: implicitHeight * 2.5
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.categories.charAt(2) === "1"
                colBackgroundToggled: Appearance.colors.colPrimary
                onClicked: {
                    var cats = WallhavenSearch.categories
                    WallhavenSearch.categories = cats.charAt(0) + cats.charAt(1) + (cats.charAt(2) === "1" ? "0" : "1")
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: Translation.tr("People")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // Purity
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledText {
            text: Translation.tr("Purity")
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.preferredWidth: 80
        }

        RowLayout {
            spacing: 12

            RippleButton {
                implicitWidth: implicitHeight * 2
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.purity.charAt(0) === "1"
                colBackgroundToggled: Appearance.colors.colPrimary
                onClicked: {
                    var p = WallhavenSearch.purity
                    WallhavenSearch.purity = (p.charAt(0) === "1" ? "0" : "1") + p.charAt(1) + p.charAt(2)
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: "SFW"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                implicitWidth: implicitHeight * 2.5
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.purity.charAt(1) === "1"
                colBackgroundToggled: Appearance.colors.colPrimary
                onClicked: {
                    var p = WallhavenSearch.purity
                    WallhavenSearch.purity = p.charAt(0) + (p.charAt(1) === "1" ? "0" : "1") + p.charAt(2)
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: Translation.tr("Sketchy")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                visible: WallhavenSearch.apiKey.length > 0
                implicitWidth: implicitHeight * 2
                implicitHeight: 32
                buttonRadius: height / 2
                toggled: WallhavenSearch.purity.charAt(2) === "1"
                colBackgroundToggled: Appearance.m3colors.m3error
                onClicked: {
                    var p = WallhavenSearch.purity
                    WallhavenSearch.purity = p.charAt(0) + p.charAt(1) + (p.charAt(2) === "1" ? "0" : "1")
                    root.triggerSearch()
                }
                contentItem: StyledText {
                    text: "NSFW"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    WindowDialogSeparator {}

    // Aspect Ratio
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledText {
            text: Translation.tr("Ratio")
            font.pixelSize: Appearance.font.pixelSize.small
            Layout.preferredWidth: 80
        }

        StyledComboBox {
            Layout.fillWidth: true
            model: [
                Translation.tr("Any"),
                "16x9", "16x10", "21x9", "32x9",
                "9x16", "10x16",
                "1x1", "3x2", "4x3", "5x4",
            ]
            property var ratioKeys: ["", "16x9", "16x10", "21x9", "32x9", "9x16", "10x16", "1x1", "3x2", "4x3", "5x4"]
            currentIndex: Math.max(0, ratioKeys.indexOf(WallhavenSearch.ratios))
            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    WallhavenSearch.ratios = ratioKeys[currentIndex]
                    root.triggerSearch()
                }
            }
        }
    }

    // Close button
    WindowDialogButtonRow {
        DialogButton {
            text: Translation.tr("Close")
            onClicked: root.dismiss()
        }
    }
}

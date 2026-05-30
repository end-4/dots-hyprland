import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

/**
 * Wallhaven search grid with search input, results grid, pagination,
 * and integrated settings popup. Drop-in replacement for the local
 * wallpaper grid when Wallhaven mode is active.
 */
Item {
    id: root

    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode
    property bool loading: WallhavenSearch.fetching
    property bool downloading: false
    property string downloadingId: ""

    signal wallpaperApplied()

    // Auto-browse on open so the grid is never empty (relevance needs a query, so
    // fall back to toplist). Lets users land on curated results without typing.
    onVisibleChanged: {
        if (visible && !WallhavenSearch.fetching && WallhavenSearch.currentResults.length === 0) {
            WallhavenSearch.browse(WallhavenSearch.sorting === "relevance" ? "toplist" : WallhavenSearch.sorting)
        }
    }

    // Black/white that reads on a given hex (relative luminance)
    function contrastColor(hex) {
        if (!hex || hex.length < 6) return Appearance.colors.colOnLayer1
        const r = parseInt(hex.substr(0, 2), 16)
        const g = parseInt(hex.substr(2, 2), 16)
        const b = parseInt(hex.substr(4, 2), 16)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 140 ? "#000000" : "#ffffff"
    }

    // Quick predefined browse modes (all return results without a query)
    readonly property var browseModes: [
        { label: Translation.tr("Top"), sort: "toplist" },
        { label: Translation.tr("Latest"), sort: "date_added" },
        { label: Translation.tr("Random"), sort: "random" },
        { label: Translation.tr("Views"), sort: "views" }
    ]

    // Broad color families. Each ORs several wallhaven palette colors (the API
    // accepts a comma-separated list) so one swatch = a wide range of wallpapers.
    // `hex` is the display swatch; `q` is the comma-joined wallhaven colors value.
    readonly property var colorGroups: [
        { hex: "cc0000", q: "660000,990000,cc0000,cc3333" },        // Red
        { hex: "ff6600", q: "ffcc33,ff9900,ff6600" },               // Orange
        { hex: "cccc33", q: "666600,999900,cccc33,ffff00" },        // Yellow
        { hex: "669900", q: "77cc33,669900,336600" },               // Green
        { hex: "66cccc", q: "66cccc,0099cc" },                      // Teal
        { hex: "0066cc", q: "0066cc,0099cc,333399" },               // Blue
        { hex: "663399", q: "ea4c88,993399,663399,333399" },        // Purple / pink
        { hex: "996633", q: "cc6633,996633,663300" },               // Brown
        { hex: "999999", q: "000000,999999,cccccc,ffffff,424153" }  // Neutral
    ]

    // Display hex of the currently-active family ("" if none) — drives the button color
    readonly property string activeHex: {
        for (let i = 0; i < colorGroups.length; i++)
            if (colorGroups[i].q === WallhavenSearch.colors) return colorGroups[i].hex
        return ""
    }

    // Public API for parent key forwarding
    function moveGridSelection(delta) { wallhavenGrid.moveSelection(delta) }
    function activateGridCurrent() { wallhavenGrid.activateCurrent() }

    // Download and apply a wallhaven wallpaper
    function downloadAndApply(wallpaper) {
        if (downloading) return
        downloading = true
        downloadingId = wallpaper.id || ""
        WallhavenSearch.downloadWallpaper(wallpaper, function(success, localPath) {
            downloading = false
            downloadingId = ""
            if (success && localPath) {
                Wallpapers.apply(localPath, root.useDarkMode)
                root.wallpaperApplied()
            }
        })
    }

    property bool showSettings: false

    // Settings popup overlay
    Loader {
        id: settingsPopupLoader
        anchors.fill: parent
        z: 100
        active: root.showSettings

        onActiveChanged: {
            if (active) {
                item.show = true
                item.forceActiveFocus()
            }
        }

        Connections {
            target: settingsPopupLoader.item
            function onDismiss() {
                if (settingsPopupLoader.item) {
                    settingsPopupLoader.item.show = false
                }
                root.showSettings = false
            }
            function onVisibleChanged() {
                if (settingsPopupLoader.item && !settingsPopupLoader.item.visible && !root.showSettings) {
                    settingsPopupLoader.active = false
                }
            }
        }

        sourceComponent: WallhavenSettingsPopup {}
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top bar: search + controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: searchBarLayout.implicitHeight + 16
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            RowLayout {
                id: searchBarLayout
                anchors {
                    fill: parent
                    margins: 8
                }
                spacing: 8

                MaterialSymbol {
                    text: "search"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: Translation.tr("Search Wallhaven...")
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer1
                    font {
                        family: Appearance.font.family.main
                        pixelSize: Appearance.font.pixelSize.small
                        hintingPreference: Font.PreferFullHinting
                        variableAxes: Appearance.font.variableAxes.main
                    }
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.colors.colOnSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    text: WallhavenSearch.currentQuery
                    background: Rectangle {
                        color: "transparent"
                    }

                    // Debounce search
                    Timer {
                        id: searchDebounce
                        interval: 500
                        onTriggered: {
                            WallhavenSearch.search(searchField.text, 1)
                        }
                    }

                    onTextChanged: {
                        searchDebounce.restart()
                    }
                    onEditingFinished: {
                        searchDebounce.stop()
                        WallhavenSearch.search(text, 1)
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true
                        }
                    }
                }

                // Inline Pagination
                RowLayout {
                    visible: WallhavenSearch.currentResults.length > 0
                    spacing: 4

                    IconToolbarButton {
                        implicitWidth: height
                        text: "navigate_before"
                        enabled: !root.loading && WallhavenSearch.currentPage > 1
                        onClicked: WallhavenSearch.previousPage()
                    }

                    TextField {
                        id: pageInput
                        implicitWidth: 40
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "" + WallhavenSearch.currentPage
                        inputMethodHints: Qt.ImhDigitsOnly
                        enabled: !root.loading
                        color: Appearance.colors.colOnLayer1
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
                            border.color: pageInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        }
                        onEditingFinished: {
                            var page = parseInt(text)
                            if (!isNaN(page) && page >= 1 && page <= WallhavenSearch.lastPage) {
                                if (page !== WallhavenSearch.currentPage)
                                    WallhavenSearch.search(WallhavenSearch.currentQuery, page)
                            } else {
                                text = "" + WallhavenSearch.currentPage
                            }
                        }

                        Connections {
                            target: WallhavenSearch
                            function onCurrentPageChanged() {
                                pageInput.text = "" + WallhavenSearch.currentPage
                            }
                        }
                    }

                    StyledText {
                        text: "/ " + WallhavenSearch.lastPage
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    IconToolbarButton {
                        implicitWidth: height
                        text: "navigate_next"
                        enabled: !root.loading && WallhavenSearch.currentPage < WallhavenSearch.lastPage
                        onClicked: WallhavenSearch.nextPage()
                    }
                }

                IconToolbarButton {
                    id: paletteButton
                    implicitWidth: height
                    text: "palette"
                    toggled: colorMenu.visible || WallhavenSearch.colors.length > 0
                    // Reflect the active color family on the button itself
                    colBackgroundToggled: root.activeHex.length > 0 ? ("#" + root.activeHex) : Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: root.activeHex.length > 0 ? ("#" + root.activeHex) : Appearance.colors.colSecondaryContainerHover
                    colText: root.activeHex.length > 0
                        ? root.contrastColor(root.activeHex)
                        : (toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant)
                    onClicked: colorMenu.visible ? colorMenu.close() : colorMenu.open()
                    StyledToolTip {
                        text: Translation.tr("Filter by color")
                    }

                    // Drop-down color grid
                    Popup {
                        id: colorMenu
                        y: paletteButton.height + 6
                        x: paletteButton.width - width
                        padding: 10
                        modal: false
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
                        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 } }

                        background: Rectangle {
                            // m3 token is opaque (colLayer1 is alpha-blended → looked see-through)
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            radius: Appearance.rounding.normal
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border
                        }

                        contentItem: ColumnLayout {
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Filter by color")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                                // Clear / any-color
                                RippleButton {
                                    visible: WallhavenSearch.colors.length > 0
                                    implicitHeight: 24
                                    leftPadding: 8
                                    rightPadding: 8
                                    buttonRadius: height / 2
                                    onClicked: { WallhavenSearch.setColor(""); colorMenu.close() }
                                    contentItem: StyledText {
                                        text: Translation.tr("Clear")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                            }

                            Grid {
                                columns: 3
                                spacing: 8
                                Repeater {
                                    model: root.colorGroups
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 44; height: 44; radius: Appearance.rounding.small
                                        color: "#" + modelData.hex
                                        border.width: WallhavenSearch.colors === modelData.q ? 3 : 1
                                        border.color: WallhavenSearch.colors === modelData.q ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { WallhavenSearch.setColor(parent.modelData.q); colorMenu.close() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                IconToolbarButton {
                    implicitWidth: height
                    text: "tune"
                    onClicked: root.showSettings = true
                    StyledToolTip {
                        text: Translation.tr("Wallhaven search settings")
                    }
                }

                IconToolbarButton {
                    implicitWidth: height
                    text: root.useDarkMode ? "dark_mode" : "light_mode"
                    onClicked: root.useDarkMode = !root.useDarkMode
                    StyledToolTip {
                        text: Translation.tr("Toggle light/dark mode for applied wallpaper")
                    }
                }
            }
        }

        // Results grid
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading indicator
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.loading && wallhavenGrid.count === 0
                spacing: 12

                MaterialLoadingIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("Searching Wallhaven...")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Error state
            ColumnLayout {
                anchors.centerIn: parent
                visible: WallhavenSearch.lastError.length > 0 && !root.loading
                spacing: 12

                MaterialSymbol {
                    text: "error"
                    iconSize: 48
                    color: Appearance.m3colors.m3error
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledText {
                    text: WallhavenSearch.lastError
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: root.width * 0.8
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.loading && WallhavenSearch.lastError.length === 0 && WallhavenSearch.currentResults.length === 0 && searchField.text.length > 0
                spacing: 12

                MaterialSymbol {
                    text: "image_not_supported"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledText {
                    text: Translation.tr("No results found")
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Initial empty state (no search yet)
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.loading && WallhavenSearch.lastError.length === 0 && WallhavenSearch.currentResults.length === 0 && searchField.text.length === 0
                spacing: 12

                MaterialSymbol {
                    text: "travel_explore"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledText {
                    text: Translation.tr("Search, or just browse:")
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
                // Quick predefined browse — no typing required
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Repeater {
                        model: root.browseModes
                        delegate: RippleButton {
                            required property var modelData
                            implicitHeight: 34
                            leftPadding: 16
                            rightPadding: 16
                            buttonRadius: height / 2
                            colBackground: Appearance.colors.colLayer1
                            onClicked: WallhavenSearch.browse(modelData.sort)
                            contentItem: StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            // Grid
            GridView {
                id: wallhavenGrid
                anchors.fill: parent
                visible: WallhavenSearch.currentResults.length > 0
                focus: true

                property int columns: root.columns
                property int currentSelection: -1
                // "first" = select first item, "last" = select last item, "" = none
                property string pendingSelectionAfterPageChange: ""

                cellWidth: width / root.columns
                cellHeight: cellWidth / root.previewCellAspectRatio
                interactive: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 64
                ScrollBar.vertical: StyledScrollBar {}

                function moveSelection(delta) {
                    if (wallhavenGrid.count === 0) return
                    var newIndex = currentSelection + delta

                    // Auto-paginate: went past the last item → next page
                    if (newIndex >= wallhavenGrid.count) {
                        if (!root.loading && WallhavenSearch.currentPage < WallhavenSearch.lastPage) {
                            pendingSelectionAfterPageChange = "first"
                            WallhavenSearch.nextPage()
                        }
                        return
                    }
                    // Auto-paginate: went before the first item → previous page
                    if (newIndex < 0) {
                        if (!root.loading && WallhavenSearch.currentPage > 1) {
                            pendingSelectionAfterPageChange = "last"
                            WallhavenSearch.previousPage()
                        }
                        return
                    }

                    currentSelection = newIndex
                    positionViewAtIndex(currentSelection, GridView.Contain)
                }

                function activateCurrent() {
                    if (currentSelection >= 0 && currentSelection < wallhavenGrid.count) {
                        var wallpaper = WallhavenSearch.currentResults[currentSelection]
                        if (wallpaper) {
                            root.downloadAndApply(wallpaper)
                        }
                    }
                }

                // After page change, select first or last item as appropriate
                Connections {
                    target: WallhavenSearch
                    function onSearchCompleted() {
                        if (wallhavenGrid.pendingSelectionAfterPageChange === "first") {
                            wallhavenGrid.currentSelection = 0
                            wallhavenGrid.positionViewAtBeginning()
                        } else if (wallhavenGrid.pendingSelectionAfterPageChange === "last") {
                            wallhavenGrid.currentSelection = wallhavenGrid.count - 1
                            wallhavenGrid.positionViewAtEnd()
                        }
                        wallhavenGrid.pendingSelectionAfterPageChange = ""
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left) {
                        moveSelection(-1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        moveSelection(1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        moveSelection(-columns)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        moveSelection(columns)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        activateCurrent()
                        event.accepted = true
                    }
                }

                model: WallhavenSearch.currentResults

                delegate: MouseArea {
                    id: wallhavenItemRoot
                    required property var modelData
                    required property int index

                    width: wallhavenGrid.cellWidth
                    height: wallhavenGrid.cellHeight
                    hoverEnabled: true

                    property string thumbnailUrl: modelData ? WallhavenSearch.getThumbnailUrl(modelData, "large") : ""
                    property string wallpaperId: modelData?.id ?? ""
                    property bool isDownloading: root.downloading && root.downloadingId === wallpaperId

                    onClicked: {
                        wallhavenGrid.currentSelection = index
                        root.downloadAndApply(modelData)
                    }

                    Rectangle {
                        id: itemBackground
                        anchors {
                            fill: parent
                            margins: Appearance.sizes.wallpaperSelectorItemMargins
                        }
                        radius: Appearance.rounding.normal
                        color: (index === wallhavenGrid.currentSelection || wallhavenItemRoot.containsMouse)
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer1

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        ColumnLayout {
                            anchors {
                                fill: parent
                                margins: Appearance.sizes.wallpaperSelectorItemPadding
                            }
                            spacing: 4

                            // Thumbnail
                            Item {
                                id: thumbnailContainer
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Image {
                                    id: thumbnailImage
                                    anchors.fill: parent
                                    source: wallhavenItemRoot.thumbnailUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: wallhavenGrid.cellWidth
                                    sourceSize.height: wallhavenGrid.cellHeight

                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: thumbnailContainer.width
                                            height: thumbnailContainer.height
                                            radius: Appearance.rounding.small
                                        }
                                    }
                                }

                                // Loading state for individual thumbnails
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer1
                                    visible: thumbnailImage.status === Image.Loading || thumbnailImage.status === Image.Error

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: thumbnailImage.status === Image.Error ? "broken_image" : "image"
                                        iconSize: Appearance.font.pixelSize.hugeass
                                        color: Appearance.colors.colSubtext
                                    }
                                }

                                // Download overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colScrim
                                    visible: wallhavenItemRoot.isDownloading

                                    MaterialLoadingIndicator {
                                        anchors.centerIn: parent
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                // Resolution badge
                                Rectangle {
                                    anchors {
                                        bottom: parent.bottom
                                        right: parent.right
                                        margins: 4
                                    }
                                    visible: modelData?.resolution ? true : false
                                    color: Appearance.colors.colScrim
                                    radius: Appearance.rounding.small
                                    implicitWidth: resolutionText.implicitWidth + 8
                                    implicitHeight: resolutionText.implicitHeight + 4

                                    StyledText {
                                        id: resolutionText
                                        anchors.centerIn: parent
                                        text: modelData?.resolution ?? ""
                                        font.pixelSize: Appearance.font.pixelSize.smaller * 0.85
                                        color: "white"
                                    }
                                }
                            }

                            // Wallpaper ID label
                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: (index === wallhavenGrid.currentSelection || wallhavenItemRoot.containsMouse)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colOnLayer1
                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                                text: wallpaperId
                            }
                        }
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallhavenGrid.width
                        height: wallhavenGrid.height
                        radius: Appearance.rounding.normal
                    }
                }
            }

            // Loading overlay when re-searching (has results but fetching new page)
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colScrim
                visible: root.loading && wallhavenGrid.count > 0
                radius: Appearance.rounding.normal

                MaterialLoadingIndicator {
                    anchors.centerIn: parent
                    color: Appearance.colors.colPrimary
                }
            }
        }
    }
}

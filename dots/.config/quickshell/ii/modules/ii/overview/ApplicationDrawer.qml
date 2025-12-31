import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Item {
    id: root
    property bool expanded: false
    property string searchText: ""
    property string sortMode: "name" // "name", "recent"
    property string filterCategory: "all" // "all", "favorites"
    
    property real collapsedHeight: 400 // Better initial height
    property real availableHeight: 0
    property real availableWidth: 0
    property real expandedHeight: {
        // Use most of available height when expanded, but leave space for top bar
        if (availableHeight > 0) {
            // Use 85% of available height to ensure it doesn't overlap top bar
            // This leaves ~15% for the bar and some breathing room
            return availableHeight * 0.85;
        }
        return 600;
    }
    property int columns: {
        if (availableWidth > 0) {
            // Calculate columns based on available width with proper spacing
            const cellWidth = 90; // Desired cell width including spacing
            return Math.max(6, Math.floor((availableWidth - 60) / cellWidth));
        }
        return Math.max(6, Math.floor((width - 60) / 90));
    }
    property real iconSize: 50
    property real spacing: 30
    
    // Context menu state
    property var contextMenuApp: null
    property bool contextMenuVisible: false
    property point contextMenuPosition: Qt.point(0, 0)
    
    // Properties dialog state
    property bool propertiesDialogVisible: false
    property var propertiesDialogApp: null
    
    implicitHeight: root.expanded ? root.expandedHeight : root.collapsedHeight
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementResize.duration
            easing.type: Appearance.animation.elementResize.type
            easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
        }
    }
    
    // Filter and sort apps
    function getFilteredApps() {
        const list = AppSearch.list;
        if (!list || list.length === 0) return [];
        
        let apps = Array.from(list);
        
        // Filter by search text
        if (root.searchText.length > 0) {
            const searchLower = root.searchText.toLowerCase();
            apps = apps.filter(app => 
                app.name.toLowerCase().includes(searchLower) ||
                (app.description && app.description.toLowerCase().includes(searchLower))
            );
        }
        
        // Sort
        if (root.sortMode === "name") {
            apps.sort((a, b) => a.name.localeCompare(b.name));
        }
        
        return apps;
    }
    
    // Get executable path from an app
    function getExecutablePath(app) {
        if (!app) return "";
        
        // Try to extract executable from the exec command
        // Desktop entries often have exec like "app-name %U" or "/path/to/app"
        const exec = app.exec || "";
        const parts = exec.split(" ");
        return parts[0] || "";
    }
    
    // Get full path using 'which' command
    function copyAppPath(app) {
        if (!app) return;
        
        const execName = getExecutablePath(app);
        if (!execName) {
            Quickshell.clipboardText = Translation.tr("Unknown executable");
            return;
        }
        
        // Use which to find the full path
        pathFinderProcess.app = app;
        pathFinderProcess.execName = execName;
        pathFinderProcess.running = true;
    }
    
    // Process to find executable path
    Process {
        id: pathFinderProcess
        property var app: null
        property string execName: ""
        
        command: ["which", execName]
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && stdout.length > 0) {
                Quickshell.clipboardText = stdout.trim();
            } else {
                // Fallback to just the exec name
                Quickshell.clipboardText = execName;
            }
        }
    }
    
    StyledRectangularShadow {
        target: drawerBackground
    }
    
    Rectangle {
        id: drawerBackground
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.expanded ? 20 : 15
            spacing: 10
            
            // Header with search and controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "apps"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer0
                }
                
                StyledText {
                    text: root.expanded ? Translation.tr("All Applications") : Translation.tr("Applications")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }
                
                Item { Layout.fillWidth: true }
                
                MaterialSymbol {
                    text: root.expanded ? "expand_less" : "expand_more"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }
            }
            
            // Search bar (only visible when expanded)
            TextField {
                id: searchField
                Layout.fillWidth: true
                visible: root.expanded
                Layout.maximumHeight: root.expanded ? implicitHeight : 0
                opacity: root.expanded ? 1 : 0
                focus: root.expanded
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                Behavior on Layout.maximumHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementResize.duration
                        easing.type: Appearance.animation.elementResize.type
                        easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                    }
                }
                
                placeholderText: Translation.tr("Search applications...")
                placeholderTextColor: Appearance.m3colors.m3outline
                padding: 10
                
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.small
                }
                
                color: Appearance.m3colors.m3onSurface
                selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                selectionColor: Appearance.colors.colSecondaryContainer
                
                background: Rectangle {
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: searchField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                
                cursorDelegate: Rectangle {
                    width: 1
                    color: Appearance.colors.colPrimary
                    radius: 1
                    visible: searchField.activeFocus
                }
                
                onTextChanged: {
                    root.searchText = text;
                }
                
                // Clear button
                MaterialSymbol {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                    visible: searchField.text.length > 0
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.text = "";
                        }
                    }
                }
            }
            
            // App Grid
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.expanded ? 100 : 40
                clip: true
                
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    cellWidth: Math.max(80, (parent.width - (root.columns - 1) * root.spacing - 30) / root.columns)
                    cellHeight: cellWidth * 1.3
                    interactive: root.expanded || contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    
                    model: ScriptModel {
                        values: root.getFilteredApps()
                    }
                    
                    // Show "no results" message
                    Label {
                        anchors.centerIn: parent
                        visible: appGrid.count === 0 && root.searchText.length > 0
                        text: Translation.tr("No applications found")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                    
                    delegate: RippleButton {
                        id: appButton
                        required property var modelData
                        required property int index
                        property bool keyboardDown: false
                        
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight
                        buttonRadius: Appearance.rounding.normal
                        colBackground: (appButton.down || appButton.keyboardDown) ? 
                            Appearance.colors.colSecondaryContainerActive : 
                            ((appButton.hovered || appButton.focus) ? 
                                Appearance.colors.colSecondaryContainer : 
                                ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 1))
                        colBackgroundHover: Appearance.colors.colSecondaryContainer
                        colRipple: Appearance.colors.colSecondaryContainerActive
                        
                        PointingHandInteraction {}
                        
                        onClicked: {
                            GlobalStates.overviewOpen = false
                            modelData.execute()
                        }
                        
                        altAction: (event) => {
                            // Right-click to show context menu
                            const globalPos = appButton.mapToItem(root, event.x, event.y);
                            root.contextMenuPosition = Qt.point(globalPos.x, globalPos.y);
                            root.contextMenuApp = appButton.modelData;
                            root.contextMenuVisible = true;
                            event.accepted = true;
                        }
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                appButton.keyboardDown = true
                                appButton.clicked()
                                event.accepted = true
                            }
                        }
                        
                        Keys.onReleased: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                appButton.keyboardDown = false
                                event.accepted = true
                            }
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            
                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                source: Quickshell.iconPath(modelData.icon, "image-missing")
                                implicitSize: root.iconSize
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer0
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                        }
                        
                        StyledToolTip {
                            text: modelData.name + (modelData.description ? "\n" + modelData.description : "")
                        }
                    }
                }
            }
        }
    }
    
    // Context Menu
    Loader {
        id: contextMenuLoader
        active: root.contextMenuVisible
        anchors.fill: parent
        
        sourceComponent: Item {
            anchors.fill: parent
            
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    root.contextMenuVisible = false;
                }
            }
            
            StyledRectangularShadow {
                target: contextMenuRect
            }
            
            Rectangle {
                id: contextMenuRect
                x: Math.min(root.contextMenuPosition.x, parent.width - width - 10)
                y: Math.min(root.contextMenuPosition.y, parent.height - height - 10)
                width: 200
                height: contextMenuColumn.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                
                ColumnLayout {
                    id: contextMenuColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        
                        onClicked: {
                            root.copyAppPath(root.contextMenuApp);
                            root.contextMenuVisible = false;
                        }
                        
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            
                            MaterialSymbol {
                                text: "content_copy"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Copy path")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                    
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        
                        onClicked: {
                            root.propertiesDialogApp = root.contextMenuApp;
                            root.propertiesDialogVisible = true;
                            root.contextMenuVisible = false;
                        }
                        
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            
                            MaterialSymbol {
                                text: "info"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Properties")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Properties Dialog
    Loader {
        id: propertiesDialogLoader
        active: root.propertiesDialogVisible
        anchors.fill: parent
        
        sourceComponent: WindowDialog {
            id: propertiesDialog
            show: root.propertiesDialogVisible
            backgroundHeight: 500
            
            onDismiss: {
                root.propertiesDialogVisible = false;
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                WindowDialogTitle {
                    Layout.fillWidth: true
                    text: Translation.tr("Application Properties")
                }
                
                RippleButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0)
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    
                    onClicked: propertiesDialog.dismiss()
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
            
            WindowDialogSeparator {
                Layout.fillWidth: true
            }
            
            StyledFlickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: propertiesColumn.implicitHeight
                clip: true
                
                ColumnLayout {
                    id: propertiesColumn
                    width: parent.width
                    spacing: 16
                    
                    // App Icon and Name
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        
                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            source: root.propertiesDialogApp ? Quickshell.iconPath(root.propertiesDialogApp.icon, "image-missing") : ""
                            implicitSize: 64
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.propertiesDialogApp ? root.propertiesDialogApp.name : ""
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    
                    WindowDialogSeparator {
                        Layout.fillWidth: true
                    }
                    
                    // Properties List
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Description
                        PropertyRow {
                            Layout.fillWidth: true
                            visible: root.propertiesDialogApp && root.propertiesDialogApp.description
                            label: Translation.tr("Description")
                            value: root.propertiesDialogApp ? (root.propertiesDialogApp.description || Translation.tr("N/A")) : ""
                        }
                        
                        // Executable
                        PropertyRow {
                            Layout.fillWidth: true
                            label: Translation.tr("Executable")
                            value: root.propertiesDialogApp ? (root.getExecutablePath(root.propertiesDialogApp) || Translation.tr("Unknown")) : ""
                        }
                        
                        // Full Command
                        PropertyRow {
                            Layout.fillWidth: true
                            visible: root.propertiesDialogApp && root.propertiesDialogApp.exec
                            label: Translation.tr("Command")
                            value: root.propertiesDialogApp ? (root.propertiesDialogApp.exec || Translation.tr("N/A")) : ""
                        }
                        
                        // Icon Name
                        PropertyRow {
                            Layout.fillWidth: true
                            label: Translation.tr("Icon")
                            value: root.propertiesDialogApp ? root.propertiesDialogApp.icon : ""
                        }
                        
                        // Desktop File
                        PropertyRow {
                            Layout.fillWidth: true
                            visible: root.propertiesDialogApp && root.propertiesDialogApp.desktopFile
                            label: Translation.tr("Desktop File")
                            value: root.propertiesDialogApp ? (root.propertiesDialogApp.desktopFile || Translation.tr("N/A")) : ""
                        }
                        
                        // Categories
                        PropertyRow {
                            Layout.fillWidth: true
                            visible: root.propertiesDialogApp && root.propertiesDialogApp.categories
                            label: Translation.tr("Categories")
                            value: root.propertiesDialogApp && root.propertiesDialogApp.categories ? 
                                (Array.isArray(root.propertiesDialogApp.categories) ? 
                                    root.propertiesDialogApp.categories.join(", ") : 
                                    root.propertiesDialogApp.categories.toString()) : 
                                Translation.tr("N/A")
                        }
                    }
                }
            }
            
            WindowDialogSeparator {
                Layout.fillWidth: true
            }
            
            WindowDialogButtonRow {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                DialogButton {
                    buttonText: Translation.tr("Close")
                    onClicked: propertiesDialog.dismiss()
                }
            }
        }
    }
    
    // Helper component for property rows
    component PropertyRow: ColumnLayout {
        id: propertyRow
        property string label: ""
        property string value: ""
        spacing: 4
        
        StyledText {
            text: propertyRow.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }
        
        StyledText {
            Layout.fillWidth: true
            text: propertyRow.value
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            wrapMode: Text.WordWrap
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    // Full screen overlay to catch outside clicks
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "project-display"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Active Tab: 0 = Display, 1 = Audio
    property int activeTab: 0

    // Dynamic Theme colors with full Material 3 fallback
    property var theme: ({
        background: "#17130b",
        surface: "#17130b",
        surface_container_lowest: "#120e07",
        surface_container_low: "#201b13",
        surface_container: "#241f17",
        surface_container_high: "#2f2921",
        surface_container_highest: "#3a342b",
        primary: "#edc06c",
        on_primary: "#412d00",
        primary_container: "#5e4200",
        on_primary_container: "#ffdea6",
        secondary: "#dac4a0",
        secondary_container: "#54452a",
        on_surface: "#ece1d4",
        on_surface_variant: "#d1c5b4",
        outline: "#9a8f80",
        outline_variant: "#4e4639",
        error: "#ffb4ab",
        error_container: "#93000a"
    })

    // Load generated colors dynamically from matugen
    FileView {
        id: themeFileView
        path: (Quickshell.env("HOME") || "") + "/.local/state/quickshell/user/generated/colors.json"
        watchChanges: true
        onLoadedChanged: {
            try {
                let parsed = JSON.parse(themeFileView.text());
                root.theme = parsed;
            } catch(e) {}
        }
    }

    // Live display & audio state parsed from hypr-monitors json
    property string activeMode: "extend-right"
    property real activeScale: 1.0
    property string activeRate: "preferred"
    property string activeRes: "auto"
    property string extName: "External Display"
    property string extPort: "HDMI-A-5"
    property string extResFormatted: ""
    property bool is4K: false
    property bool isTV: false
    property bool hasExternal: false
    property bool vrrEnabled: false
    property int brightnessVal: 80
    property bool extDpms: true
    property bool nightLightEnabled: false
    property int nightLightTemp: 4500

    property var availableRates: [60, 75, 100]
    property var availableResolutions: ["1920x1080", "1360x768", "1280x720"]

    property var audioSinks: []
    property var audioSources: []

    // Runner for hypr-monitors commands
    function runCommand(args) {
        cmdProc.command = args;
        cmdProc.running = true;
    }

    function refreshState() {
        jsonProc.running = false;
        jsonProc.running = true;
    }

    // Actions
    function applyMode(mode) {
        activeMode = mode;
        runCommand(["hypr-monitors", "mode", mode]);
        refreshTimer.restart();
    }

    function applyScale(scale) {
        activeScale = scale;
        runCommand(["hypr-monitors", "scale", scale.toString()]);
        refreshTimer.restart();
    }

    function applyRate(rate) {
        activeRate = rate.toString();
        runCommand(["hypr-monitors", "rate", rate.toString()]);
        refreshTimer.restart();
    }

    function applyRes(res) {
        activeRes = res;
        runCommand(["hypr-monitors", "res", res]);
        refreshTimer.restart();
    }

    function toggleVRR() {
        vrrEnabled = !vrrEnabled;
        runCommand(["hypr-monitors", "vrr", vrrEnabled ? "on" : "off"]);
        refreshTimer.restart();
    }

    function setBrightness(b) {
        brightnessVal = b;
        runCommand(["hypr-monitors", "brightness", b.toString()]);
    }

    function toggleNightLight() {
        nightLightEnabled = !nightLightEnabled;
        runCommand(["hypr-monitors", "sunset", nightLightEnabled ? nightLightTemp.toString() : "off"]);
    }

    function setNightLightTemp(t) {
        nightLightTemp = t;
        if (nightLightEnabled) {
            runCommand(["hypr-monitors", "sunset", t.toString()]);
        }
    }

    function toggleDPMS() {
        runCommand(["hypr-monitors", "dpms", "toggle"]);
        refreshTimer.restart();
    }

    function selectAudioSink(sinkId) {
        runCommand(["hypr-monitors", "audio-sink", sinkId.toString()]);
        refreshTimer.restart();
    }

    function selectAudioSource(sourceId) {
        runCommand(["hypr-monitors", "audio-source", sourceId.toString()]);
        refreshTimer.restart();
    }

    function setDeviceVolume(devId, pct) {
        runCommand(["hypr-monitors", "audio-volume", devId.toString(), pct.toString()]);
        refreshTimer.restart();
    }

    function toggleDeviceMute(devId) {
        runCommand(["hypr-monitors", "audio-mute", devId.toString()]);
        refreshTimer.restart();
    }

    Process {
        id: cmdProc
        running: false
    }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: refreshState()
    }

    // Process to query full monitor and audio JSON from hypr-monitors
    Process {
        id: jsonProc
        command: ["hypr-monitors", "json"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const parsed = JSON.parse(data);
                    root.hasExternal = parsed.has_external;
                    root.activeMode = parsed.mode || "extend-right";
                    root.activeScale = parsed.ext_scale || 1.0;
                    root.vrrEnabled = parsed.vrr || false;
                    root.brightnessVal = parsed.brightness || 80;

                    if (parsed.night_light) {
                        root.nightLightEnabled = parsed.night_light.enabled || false;
                        root.nightLightTemp = parsed.night_light.temp || 4500;
                    }

                    if (parsed.external) {
                        root.extName = parsed.external.description || parsed.external.name || "External Display";
                        root.extPort = parsed.external.name || "HDMI-A-5";
                        root.extResFormatted = parsed.external.width + "x" + parsed.external.height + " @" + parsed.external.rate + "Hz";
                        root.is4K = parsed.external.is_4k || false;
                        root.isTV = parsed.external.is_tv || false;
                        root.extDpms = parsed.external.dpms !== false;
                        if (parsed.external.available_rates && parsed.external.available_rates.length > 0)
                            root.availableRates = parsed.external.available_rates;
                        if (parsed.external.available_resolutions && parsed.external.available_resolutions.length > 0)
                            root.availableResolutions = parsed.external.available_resolutions;
                    } else {
                        root.extName = "Laptop Screen (eDP-1)";
                        root.extResFormatted = "1920x1080 @144Hz";
                        root.is4K = false;
                        root.isTV = false;
                    }

                    root.audioSinks = parsed.sinks || [];
                    root.audioSources = parsed.sources || [];
                } catch(e) {}
            }
        }
    }

    // Fullscreen backdrop: clicking anywhere outside closes flyout
    MouseArea {
        id: backdropArea
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: Qt.quit()
    }

    // Main Flyout Card
    Rectangle {
        id: card
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            topMargin: 12
            bottomMargin: 12
            rightMargin: 12
        }
        width: 460
        color: root.theme.surface_container
        radius: 24
        border.color: root.theme.outline_variant
        border.width: 1

        // Consume clicks to prevent dismissing
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        focus: true
        Keys.onEscapePressed: Qt.quit()
        Keys.onTabPressed: activeTab = (activeTab === 0 ? 1 : 0)
        Keys.onDigit1Pressed: applyMode("laptop-only")
        Keys.onDigit2Pressed: if (hasExternal) applyMode("mirror")
        Keys.onDigit3Pressed: if (hasExternal) applyMode("extend-right")
        Keys.onDigit4Pressed: if (hasExternal) applyMode("second-only")

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Header Icon
                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: 12
                    color: root.theme.primary_container

                    Text {
                        anchors.centerIn: parent
                        text: activeTab === 0 ? "desktop_windows" : "volume_up"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: root.theme.on_primary_container
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Display & Audio"
                        font.family: "Google Sans Flex"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: root.theme.on_surface
                    }

                    Text {
                        text: "Super + P Quick Projection Center"
                        font.family: "Google Sans Flex"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: root.theme.on_surface_variant
                    }
                }

                // Refresh Button
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: refreshHover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high
                    border.color: root.theme.outline_variant
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: root.theme.on_surface_variant
                    }

                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: refreshState()
                    }
                }

                // Close Button
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: closeHover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high
                    border.color: root.theme.outline_variant
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: root.theme.on_surface
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            // --- SEGMENTED TABS (Display / Audio) ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 12
                color: root.theme.surface_container_lowest
                border.color: root.theme.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 6

                    // Display Tab Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: activeTab === 0 ? root.theme.primary : (tab1Hover.containsMouse ? root.theme.surface_container_high : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "desktop_windows"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: activeTab === 0 ? root.theme.on_primary : root.theme.on_surface_variant
                            }

                            Text {
                                text: "Display"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 13
                                font.weight: activeTab === 0 ? Font.DemiBold : Font.Medium
                                color: activeTab === 0 ? root.theme.on_primary : root.theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            id: tab1Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = 0
                        }
                    }

                    // Audio Tab Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: activeTab === 1 ? root.theme.primary : (tab2Hover.containsMouse ? root.theme.surface_container_high : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "volume_up"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: activeTab === 1 ? root.theme.on_primary : root.theme.on_surface_variant
                            }

                            Text {
                                text: "Audio & Sound"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 13
                                font.weight: activeTab === 1 ? Font.DemiBold : Font.Medium
                                color: activeTab === 1 ? root.theme.on_primary : root.theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            id: tab2Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = 1
                        }
                    }
                }
            }

            // --- TAB CONTENT ---
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                // ==========================================
                // 1. TAB 0: DISPLAY CONFIGURATION
                // ==========================================
                ColumnLayout {
                    visible: activeTab === 0
                    width: card.width - 40
                    spacing: 14

                    // A. VISUAL MONITOR ARRANGEMENT PREVIEW
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 126
                        radius: 16
                        color: root.theme.surface_container_high
                        border.color: root.theme.outline_variant
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "ARRANGEMENT PREVIEW"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: root.theme.primary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: hasExternal ? (activeMode === "mirror" ? "Duplicate / Cloned" : (activeMode === "second-only" ? "Second Screen Only" : (activeMode === "laptop-only" ? "PC Screen Only" : "Extended Desktop"))) : "Single Display"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: root.theme.on_surface_variant
                                }
                            }

                            // Interactive Spatial Canvas
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // Extend Right (Laptop Left, Ext Right)
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 14
                                    visible: activeMode === "extend-right"

                                    Rectangle {
                                        width: 115; height: 60; radius: 10
                                        color: root.theme.surface_container_highest
                                        border.color: root.theme.outline
                                        border.width: 1
                                        Column {
                                            anchors.centerIn: parent; spacing: 3
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                                                Text { text: "laptop"; font.family: "Material Symbols Rounded"; font.pixelSize: 14; color: root.theme.on_surface }
                                                Text { text: "Screen 1"; font.family: "Google Sans Flex"; font.pixelSize: 11; font.weight: Font.DemiBold; color: root.theme.on_surface }
                                            }
                                            Text { text: "eDP-1 (Laptop)"; font.family: "Google Sans Flex"; font.pixelSize: 9; color: root.theme.on_surface_variant; anchors.horizontalCenter: parent.horizontalCenter }
                                        }
                                    }

                                    Rectangle {
                                        width: 130; height: 66; radius: 10
                                        color: root.theme.primary_container
                                        border.color: root.theme.primary
                                        border.width: 1.5
                                        Column {
                                            anchors.centerIn: parent; spacing: 3
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                                                Text { text: isTV ? "tv" : "desktop_windows"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: root.theme.primary }
                                                Text { text: isTV ? "TV Screen" : "Screen 2"; font.family: "Google Sans Flex"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_primary_container }
                                            }
                                            Text { text: extPort; font.family: "Google Sans Flex"; font.pixelSize: 9; font.weight: Font.DemiBold; color: root.theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                        }
                                    }
                                }

                                // Extend Left (Ext Left, Laptop Right)
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 14
                                    visible: activeMode === "extend-left"

                                    Rectangle {
                                        width: 130; height: 66; radius: 10
                                        color: root.theme.primary_container
                                        border.color: root.theme.primary
                                        border.width: 1.5
                                        Column {
                                            anchors.centerIn: parent; spacing: 3
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                                                Text { text: isTV ? "tv" : "desktop_windows"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: root.theme.primary }
                                                Text { text: isTV ? "TV Screen" : "Screen 2"; font.family: "Google Sans Flex"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_primary_container }
                                            }
                                            Text { text: extPort; font.family: "Google Sans Flex"; font.pixelSize: 9; font.weight: Font.DemiBold; color: root.theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                        }
                                    }

                                    Rectangle {
                                        width: 115; height: 60; radius: 10
                                        color: root.theme.surface_container_highest
                                        border.color: root.theme.outline
                                        border.width: 1
                                        Column {
                                            anchors.centerIn: parent; spacing: 3
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                                                Text { text: "laptop"; font.family: "Material Symbols Rounded"; font.pixelSize: 14; color: root.theme.on_surface }
                                                Text { text: "Screen 1"; font.family: "Google Sans Flex"; font.pixelSize: 11; font.weight: Font.DemiBold; color: root.theme.on_surface }
                                            }
                                            Text { text: "eDP-1 (Laptop)"; font.family: "Google Sans Flex"; font.pixelSize: 9; color: root.theme.on_surface_variant; anchors.horizontalCenter: parent.horizontalCenter }
                                        }
                                    }
                                }

                                // Extend Above (Ext Above, Laptop Below)
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: activeMode === "extend-above"

                                    Rectangle {
                                        width: 135; height: 36; radius: 8
                                        color: root.theme.primary_container
                                        border.color: root.theme.primary
                                        border.width: 1.5
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Row {
                                            anchors.centerIn: parent; spacing: 5
                                            Text { text: isTV ? "tv" : "desktop_windows"; font.family: "Material Symbols Rounded"; font.pixelSize: 14; color: root.theme.primary }
                                            Text { text: "Screen 2 (Above)"; font.family: "Google Sans Flex"; font.pixelSize: 10; font.weight: Font.Bold; color: root.theme.on_primary_container }
                                        }
                                    }
                                    Rectangle {
                                        width: 115; height: 32; radius: 8
                                        color: root.theme.surface_container_highest
                                        border.color: root.theme.outline
                                        border.width: 1
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Row {
                                            anchors.centerIn: parent; spacing: 5
                                            Text { text: "laptop"; font.family: "Material Symbols Rounded"; font.pixelSize: 14; color: root.theme.on_surface }
                                            Text { text: "Screen 1 (Laptop)"; font.family: "Google Sans Flex"; font.pixelSize: 10; font.weight: Font.Medium; color: root.theme.on_surface }
                                        }
                                    }
                                }

                                // Duplicate / Mirror Mode
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 180; height: 60; radius: 12
                                    color: root.theme.primary_container
                                    border.color: root.theme.primary
                                    border.width: 1.5
                                    visible: activeMode === "mirror"
                                    Column {
                                        anchors.centerIn: parent; spacing: 3
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                            Text { text: "content_copy"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: root.theme.primary }
                                            Text { text: "Mirrored 1:1"; font.family: "Google Sans Flex"; font.pixelSize: 12; font.weight: Font.Bold; color: root.theme.on_primary_container }
                                        }
                                        Text { text: "Exact duplicate on both displays"; font.family: "Google Sans Flex"; font.pixelSize: 10; color: root.theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }

                                // Second Only Mode
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 180; height: 60; radius: 12
                                    color: root.theme.primary_container
                                    border.color: root.theme.primary
                                    border.width: 1.5
                                    visible: activeMode === "second-only"
                                    Column {
                                        anchors.centerIn: parent; spacing: 3
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                            Text { text: isTV ? "tv" : "desktop_windows"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: root.theme.primary }
                                            Text { text: isTV ? "TV Screen Only" : "Screen 2 Only"; font.family: "Google Sans Flex"; font.pixelSize: 12; font.weight: Font.Bold; color: root.theme.on_primary_container }
                                        }
                                        Text { text: "Laptop screen is off"; font.family: "Google Sans Flex"; font.pixelSize: 10; color: root.theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }

                                // Laptop Only Mode
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 180; height: 60; radius: 12
                                    color: root.theme.surface_container_highest
                                    border.color: root.theme.outline
                                    border.width: 1
                                    visible: activeMode === "laptop-only" || !hasExternal
                                    Column {
                                        anchors.centerIn: parent; spacing: 3
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                            Text { text: "laptop"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: root.theme.primary }
                                            Text { text: "Laptop Only"; font.family: "Google Sans Flex"; font.pixelSize: 12; font.weight: Font.Bold; color: root.theme.on_surface }
                                        }
                                        Text { text: "Single internal display active"; font.family: "Google Sans Flex"; font.pixelSize: 10; color: root.theme.on_surface_variant; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }
                            }
                        }
                    }

                    // B. PROJECTION MODES (4 Cards)
                    Text {
                        text: "PROJECTION MODE"
                        font.family: "Google Sans Flex"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.theme.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // 1. PC Screen Only
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: 12
                            color: activeMode === "laptop-only" ? root.theme.primary_container : (m1Hover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                            border.color: activeMode === "laptop-only" ? root.theme.primary : root.theme.outline_variant
                            border.width: activeMode === "laptop-only" ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "laptop"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    color: activeMode === "laptop-only" ? root.theme.primary : root.theme.on_surface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "PC screen only"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: activeMode === "laptop-only" ? root.theme.on_primary_container : root.theme.on_surface
                                    }
                                    Text {
                                        text: "Disconnect external monitor"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 11
                                        color: activeMode === "laptop-only" ? root.theme.primary : root.theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 22; implicitHeight: 22; radius: 6
                                    color: root.theme.surface_container_lowest
                                    Text { anchors.centerIn: parent; text: "1"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_surface_variant }
                                }

                                Text {
                                    visible: activeMode === "laptop-only"
                                    text: "check_circle"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }
                            }

                            MouseArea {
                                id: m1Hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyMode("laptop-only")
                            }
                        }

                        // 2. Duplicate
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: 12
                            opacity: hasExternal ? 1.0 : 0.4
                            color: activeMode === "mirror" ? root.theme.primary_container : (m2Hover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                            border.color: activeMode === "mirror" ? root.theme.primary : root.theme.outline_variant
                            border.width: activeMode === "mirror" ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "content_copy"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    color: activeMode === "mirror" ? root.theme.primary : root.theme.on_surface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Duplicate (Mirror)"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: activeMode === "mirror" ? root.theme.on_primary_container : root.theme.on_surface
                                    }
                                    Text {
                                        text: "Show the same screen on both displays"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 11
                                        color: activeMode === "mirror" ? root.theme.primary : root.theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 22; implicitHeight: 22; radius: 6
                                    color: root.theme.surface_container_lowest
                                    Text { anchors.centerIn: parent; text: "2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_surface_variant }
                                }

                                Text {
                                    visible: activeMode === "mirror"
                                    text: "check_circle"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }
                            }

                            MouseArea {
                                id: m2Hover
                                anchors.fill: parent
                                enabled: hasExternal
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyMode("mirror")
                            }
                        }

                        // 3. Extend Desktop
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: 12
                            opacity: hasExternal ? 1.0 : 0.4
                            color: activeMode.startsWith("extend") ? root.theme.primary_container : (m3Hover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                            border.color: activeMode.startsWith("extend") ? root.theme.primary : root.theme.outline_variant
                            border.width: activeMode.startsWith("extend") ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "splitscreen"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    color: activeMode.startsWith("extend") ? root.theme.primary : root.theme.on_surface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Extend Desktop"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: activeMode.startsWith("extend") ? root.theme.on_primary_container : root.theme.on_surface
                                    }
                                    Text {
                                        text: "Expand workspace across both displays"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 11
                                        color: activeMode.startsWith("extend") ? root.theme.primary : root.theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 22; implicitHeight: 22; radius: 6
                                    color: root.theme.surface_container_lowest
                                    Text { anchors.centerIn: parent; text: "3"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_surface_variant }
                                }

                                Text {
                                    visible: activeMode.startsWith("extend")
                                    text: "check_circle"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }
                            }

                            MouseArea {
                                id: m3Hover
                                anchors.fill: parent
                                enabled: hasExternal
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyMode("extend-right")
                            }
                        }

                        // 4. Second Screen Only
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: 12
                            opacity: hasExternal ? 1.0 : 0.4
                            color: activeMode === "second-only" ? root.theme.primary_container : (m4Hover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                            border.color: activeMode === "second-only" ? root.theme.primary : root.theme.outline_variant
                            border.width: activeMode === "second-only" ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: isTV ? "tv" : "desktop_windows"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    color: activeMode === "second-only" ? root.theme.primary : root.theme.on_surface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: isTV ? "TV display only" : "Second screen only"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: activeMode === "second-only" ? root.theme.on_primary_container : root.theme.on_surface
                                    }
                                    Text {
                                        text: "Turn off laptop screen (Docked mode)"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 11
                                        color: activeMode === "second-only" ? root.theme.primary : root.theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 22; implicitHeight: 22; radius: 6
                                    color: root.theme.surface_container_lowest
                                    Text { anchors.centerIn: parent; text: "4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: root.theme.on_surface_variant }
                                }

                                Text {
                                    visible: activeMode === "second-only"
                                    text: "check_circle"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }
                            }

                            MouseArea {
                                id: m4Hover
                                anchors.fill: parent
                                enabled: hasExternal
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyMode("second-only")
                            }
                        }
                    }

                    // Extend Direction Pills (when extend is active)
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: hasExternal && activeMode.startsWith("extend")
                        spacing: 6

                        Text {
                            text: "EXTEND DIRECTION"
                            font.family: "Google Sans Flex"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.theme.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { label: "Left", icon: "arrow_back", mode: "extend-left" },
                                    { label: "Right", icon: "arrow_forward", mode: "extend-right" },
                                    { label: "Above", icon: "arrow_upward", mode: "extend-above" }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    radius: 8
                                    color: activeMode === modelData.mode ? root.theme.primary : (dirArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                                    border.color: activeMode === modelData.mode ? root.theme.primary : root.theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                            color: activeMode === modelData.mode ? root.theme.on_primary : root.theme.on_surface
                                        }
                                        Text {
                                            text: modelData.label
                                            font.family: "Google Sans Flex"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: activeMode === modelData.mode ? root.theme.on_primary : root.theme.on_surface
                                        }
                                    }

                                    MouseArea {
                                        id: dirArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: applyMode(modelData.mode)
                                    }
                                }
                            }
                        }
                    }

                    // C. HARDWARE DISPLAY SETTINGS & TUNING
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: hwCol.implicitHeight + 24
                        radius: 16
                        color: root.theme.surface_container_high
                        border.color: root.theme.outline_variant
                        border.width: 1
                        visible: hasExternal

                        ColumnLayout {
                            id: hwCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            // Header row with Device Name + Standby Sleep Button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: isTV ? "tv" : "desktop_windows"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: extName
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: root.theme.on_surface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: extResFormatted + " • " + extPort + (isTV ? " [TV Mode]" : "")
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: root.theme.on_surface_variant
                                    }
                                }

                                // Standby DPMS Button
                                Rectangle {
                                    implicitWidth: dpmsRow.implicitWidth + 14
                                    implicitHeight: 28
                                    radius: 8
                                    color: extDpms ? (dpmsArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_lowest) : root.theme.error_container
                                    border.color: extDpms ? root.theme.outline_variant : root.theme.error
                                    border.width: 1

                                    RowLayout {
                                        id: dpmsRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: "power_settings_new"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                            color: extDpms ? root.theme.on_surface_variant : root.theme.error
                                        }
                                        Text {
                                            text: extDpms ? "Sleep" : "Wake"
                                            font.family: "Google Sans Flex"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: extDpms ? root.theme.on_surface : root.theme.error
                                        }
                                    }

                                    MouseArea {
                                        id: dpmsArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: toggleDPMS()
                                    }
                                }
                            }

                            // Resolution Chips
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "RESOLUTION"
                                        font.family: "Google Sans Flex"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: root.theme.primary
                                    }
                                    Item { Layout.fillWidth: true }
                                    // VRR Toggle Pill
                                    Rectangle {
                                        implicitWidth: vrrRow.implicitWidth + 12
                                        implicitHeight: 24
                                        radius: 6
                                        color: vrrEnabled ? root.theme.primary : root.theme.surface_container_lowest
                                        border.color: vrrEnabled ? root.theme.primary : root.theme.outline_variant
                                        border.width: 1

                                        RowLayout {
                                            id: vrrRow
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "bolt"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 14
                                                color: vrrEnabled ? root.theme.on_primary : root.theme.on_surface_variant
                                            }
                                            Text {
                                                text: vrrEnabled ? "VRR: ON" : "VRR: OFF"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: vrrEnabled ? root.theme.on_primary : root.theme.on_surface_variant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: toggleVRR()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: ["1360x768", "1920x1080", "1280x720", "auto"]
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            radius: 8
                                            color: (activeRes === modelData || (modelData === "auto" && activeRes === "auto")) ? root.theme.primary : (resArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_lowest)
                                            border.color: (activeRes === modelData) ? root.theme.primary : root.theme.outline_variant
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData === "auto" ? "Auto" : (modelData === "1360x768" ? "1360x768 ★" : modelData)
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: (activeRes === modelData || (modelData === "auto" && activeRes === "auto")) ? root.theme.on_primary : root.theme.on_surface
                                            }

                                            MouseArea {
                                                id: resArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: applyRes(modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            // Refresh Rate Chips
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "REFRESH RATE"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: root.theme.primary
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: availableRates
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 28
                                            radius: 8
                                            color: (activeRate === modelData.toString()) ? root.theme.primary : (hzArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_lowest)
                                            border.color: (activeRate === modelData.toString()) ? root.theme.primary : root.theme.outline_variant
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData + " Hz"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                color: (activeRate === modelData.toString()) ? root.theme.on_primary : root.theme.on_surface
                                            }

                                            MouseArea {
                                                id: hzArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: applyRate(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // C2. INTERNAL DISPLAY STATUS (when no external display is connected)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 64
                        radius: 16
                        color: root.theme.surface_container_high
                        border.color: root.theme.outline_variant
                        border.width: 1
                        visible: !hasExternal

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                implicitWidth: 36; implicitHeight: 36; radius: 10
                                color: root.theme.surface_container_lowest
                                Text {
                                    anchors.centerIn: parent
                                    text: "laptop"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    color: root.theme.primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "Laptop Display (eDP-1)"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: root.theme.on_surface
                                }
                                Text {
                                    text: "1920x1080 @ 144Hz • Connect HDMI to Project"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 11
                                    color: root.theme.on_surface_variant
                                }
                            }
                        }
                    }

                    // D. HARDWARE / SCREEN BRIGHTNESS
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        radius: 16
                        color: root.theme.surface_container_high
                        border.color: root.theme.outline_variant
                        border.width: 1
                        visible: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "brightness_6"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: root.theme.primary
                                }
                                Text {
                                    text: hasExternal ? "HARDWARE BRIGHTNESS (DDC/CI)" : "SCREEN BRIGHTNESS"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: root.theme.on_surface
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: brightnessVal + "%"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: root.theme.primary
                                }
                            }

                            // Slider Track
                            Rectangle {
                                id: bSliderTrack
                                Layout.fillWidth: true
                                implicitHeight: 10
                                radius: 5
                                color: root.theme.surface_container_lowest

                                Rectangle {
                                    width: Math.max(10, bSliderTrack.width * (brightnessVal / 100))
                                    height: parent.height
                                    radius: 5
                                    color: root.theme.primary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: mouse => {
                                        if (pressed) {
                                            let pct = Math.round(Math.max(10, Math.min(100, (mouse.x / width) * 100)));
                                            setBrightness(pct);
                                        }
                                    }
                                    onPressed: mouse => {
                                        let pct = Math.round(Math.max(10, Math.min(100, (mouse.x / width) * 100)));
                                        setBrightness(pct);
                                    }
                                }
                            }
                        }
                    }

                    // E. NIGHT LIGHT / SCREEN WARMTH
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        radius: 16
                        color: root.theme.surface_container_high
                        border.color: root.theme.outline_variant
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "nightlight"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: root.theme.primary
                                }
                                Text {
                                    text: "NIGHT LIGHT / WARMTH"
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: root.theme.on_surface
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: nightLightEnabled ? (nightLightTemp + "K") : "OFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: nightLightEnabled ? root.theme.primary : root.theme.on_surface_variant
                                }

                                // Toggle Switch Pill
                                Rectangle {
                                    implicitWidth: 42; implicitHeight: 22; radius: 11
                                    color: nightLightEnabled ? root.theme.primary : root.theme.surface_container_lowest
                                    border.color: root.theme.outline_variant
                                    border.width: 1

                                    Rectangle {
                                        width: 16; height: 16; radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: nightLightEnabled ? 23 : 3
                                        color: nightLightEnabled ? root.theme.on_primary : root.theme.on_surface_variant
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: toggleNightLight()
                                    }
                                }
                            }

                            // Warmth Slider Track
                            Rectangle {
                                id: nlSliderTrack
                                Layout.fillWidth: true
                                implicitHeight: 10
                                radius: 5
                                opacity: nightLightEnabled ? 1.0 : 0.35
                                color: root.theme.surface_container_lowest

                                Rectangle {
                                    width: Math.max(10, nlSliderTrack.width * ((6500 - nightLightTemp) / 3500))
                                    height: parent.height
                                    radius: 5
                                    color: "#ffaa66"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: nightLightEnabled
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: mouse => {
                                        if (pressed) {
                                            let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                            let t = Math.round(6500 - (ratio * 3500));
                                            setNightLightTemp(t);
                                        }
                                    }
                                    onPressed: mouse => {
                                        let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        let t = Math.round(6500 - (ratio * 3500));
                                        setNightLightTemp(t);
                                    }
                                }
                            }
                        }
                    }

                    Item { implicitHeight: 10 }
                }

                // ==========================================
                // 2. TAB 1: AUDIO CONFIGURATION (SINKS & SOURCES)
                // ==========================================
                ColumnLayout {
                    visible: activeTab === 1
                    width: card.width - 40
                    spacing: 16

                    // OUTPUT DEVICES (SINKS)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "volume_up"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: root.theme.primary
                            }
                            Text {
                                text: "OUTPUT DEVICES (SPEAKERS / TV)"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: root.theme.primary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: audioSinks.length + " available"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                color: root.theme.on_surface_variant
                            }
                        }

                        Repeater {
                            model: audioSinks
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 74
                                radius: 14
                                color: modelData.active ? root.theme.surface_container_highest : (sinkCardArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                                border.color: modelData.active ? root.theme.primary : root.theme.outline_variant
                                border.width: modelData.active ? 1.5 : 1

                                MouseArea {
                                    id: sinkCardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectAudioSink(modelData.id)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    // Top Row: Icon, Device Name, Active Radio (Clickable to switch device)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: modelData.name.toLowerCase().includes("hdmi") ? "tv" : (modelData.name.toLowerCase().includes("headset") ? "headphones" : "speaker")
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: modelData.active ? root.theme.primary : root.theme.on_surface_variant
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: modelData.name
                                                font.family: "Google Sans Flex"
                                                font.pixelSize: 13
                                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                color: modelData.active ? root.theme.on_surface : root.theme.on_surface_variant
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Text {
                                            text: modelData.active ? "check_circle" : "radio_button_unchecked"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: modelData.active ? root.theme.primary : root.theme.outline
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: selectAudioSink(modelData.id)
                                        }
                                    }

                                    // Bottom Row: Volume Slider + Percentage + Mute Toggle
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: modelData.muted ? "volume_off" : "volume_up"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                            color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                        }

                                        // Interactive Volume Track
                                        Rectangle {
                                            id: volTrack
                                            Layout.fillWidth: true
                                            implicitHeight: 8
                                            radius: 4
                                            color: root.theme.surface_container_lowest

                                            Rectangle {
                                                width: Math.max(6, volTrack.width * (Math.min(100, modelData.volume) / 100))
                                                height: parent.height
                                                radius: 4
                                                color: modelData.muted ? root.theme.error : root.theme.primary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onPositionChanged: mouse => {
                                                    if (pressed) {
                                                        let pct = Math.round(Math.max(0, Math.min(100, (mouse.x / width) * 100)));
                                                        setDeviceVolume(modelData.id, pct);
                                                    }
                                                }
                                                onPressed: mouse => {
                                                    let pct = Math.round(Math.max(0, Math.min(100, (mouse.x / width) * 100)));
                                                    setDeviceVolume(modelData.id, pct);
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.muted ? "MUTED" : (modelData.volume + "%")
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                        }

                                        // Mute Toggle Button
                                        Rectangle {
                                            implicitWidth: 26; implicitHeight: 22; radius: 6
                                            color: modelData.muted ? root.theme.error_container : root.theme.surface_container_lowest
                                            border.color: root.theme.outline_variant
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.muted ? "volume_off" : "volume_up"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 13
                                                color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: toggleDeviceMute(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // INPUT DEVICES (SOURCES / MICROPHONES)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "mic"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: root.theme.primary
                            }
                            Text {
                                text: "INPUT DEVICES (MICROPHONES)"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: root.theme.primary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: audioSources.length + " available"
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                color: root.theme.on_surface_variant
                            }
                        }

                        Repeater {
                            model: audioSources
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 74
                                radius: 14
                                color: modelData.active ? root.theme.surface_container_highest : (srcCardArea.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high)
                                border.color: modelData.active ? root.theme.primary : root.theme.outline_variant
                                border.width: modelData.active ? 1.5 : 1

                                MouseArea {
                                    id: srcCardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectAudioSource(modelData.id)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    // Top Row: Icon, Device Name, Active Radio (Clickable to switch device)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: modelData.name.toLowerCase().includes("headset") ? "headphones" : "mic"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: modelData.active ? root.theme.primary : root.theme.on_surface_variant
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: modelData.name
                                                font.family: "Google Sans Flex"
                                                font.pixelSize: 13
                                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                color: modelData.active ? root.theme.on_surface : root.theme.on_surface_variant
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Text {
                                            text: modelData.active ? "check_circle" : "radio_button_unchecked"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: modelData.active ? root.theme.primary : root.theme.outline
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: selectAudioSource(modelData.id)
                                        }
                                    }

                                    // Bottom Row: Level Track + Percentage + Mute Toggle
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: modelData.muted ? "mic_off" : "mic"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                            color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                        }

                                        Rectangle {
                                            id: srcTrack
                                            Layout.fillWidth: true
                                            implicitHeight: 8
                                            radius: 4
                                            color: root.theme.surface_container_lowest

                                            Rectangle {
                                                width: Math.max(6, srcTrack.width * (Math.min(100, modelData.volume) / 100))
                                                height: parent.height
                                                radius: 4
                                                color: modelData.muted ? root.theme.error : root.theme.primary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onPositionChanged: mouse => {
                                                    if (pressed) {
                                                        let pct = Math.round(Math.max(0, Math.min(100, (mouse.x / width) * 100)));
                                                        setDeviceVolume(modelData.id, pct);
                                                    }
                                                }
                                                onPressed: mouse => {
                                                    let pct = Math.round(Math.max(0, Math.min(100, (mouse.x / width) * 100)));
                                                    setDeviceVolume(modelData.id, pct);
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.muted ? "MUTED" : (modelData.volume + "%")
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                        }

                                        // Mute Toggle Button
                                        Rectangle {
                                            implicitWidth: 26; implicitHeight: 22; radius: 6
                                            color: modelData.muted ? root.theme.error_container : root.theme.surface_container_lowest
                                            border.color: root.theme.outline_variant
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.muted ? "mic_off" : "mic"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 13
                                                color: modelData.muted ? root.theme.error : root.theme.on_surface_variant
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: toggleDeviceMute(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { implicitHeight: 10 }
                }
            }

            // --- FOOTER BAR ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Auto-Detect Displays Button
                Rectangle {
                    implicitWidth: detectRow.implicitWidth + 20
                    implicitHeight: 32
                    radius: 10
                    color: detectHover.containsMouse ? root.theme.surface_container_highest : root.theme.surface_container_high
                    border.color: root.theme.outline_variant
                    border.width: 1

                    RowLayout {
                        id: detectRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "sync"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: root.theme.primary
                        }
                        Text {
                            text: "Auto-Detect"
                            font.family: "Google Sans Flex"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.theme.on_surface
                        }
                    }

                    MouseArea {
                        id: detectHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            runCommand(["hypr-monitors", "auto"]);
                            refreshTimer.restart();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Esc or click outside to dismiss"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    color: root.theme.on_surface_variant
                }
            }
        }
    }
}

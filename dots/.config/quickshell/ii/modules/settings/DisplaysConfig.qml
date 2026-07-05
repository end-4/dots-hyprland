import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    readonly property string monitorsLua: FileUtils.trimFileProtocol(`${Directories.config}/hypr/monitors.lua`)

    property var monitors: []
    property int selectedIndex: 0
    readonly property var selMon: (monitors.length > 0 && selectedIndex < monitors.length) ? monitors[selectedIndex] : null

    property bool identifyOverlayVisible: false
    property string identifyingMonitorName: ""
    property int secondaryWorkspace: 10
    property string selectedSecondaryMonitor: ""

    property int previewCountdown: 0
    property bool previewActive: false
    property var previewSnapshot: []
    property string previewLuaContent: ""
    property var committedState: []

    property var expandedStates: ({})
    property int _rev: 0

    readonly property bool hasChanges: {
        root._rev;
        return JSON.stringify(root.monitors) !== JSON.stringify(root.committedState);
    }

    function logicalW(m) {
        const w = (m.transform % 2 === 1) ? m.resH : m.resW;
        return w / m.monScale;
    }
    function logicalH(m) {
        const h = (m.transform % 2 === 1) ? m.resW : m.resH;
        return h / m.monScale;
    }

    function primaryMonitor() {
        const list = root.monitors;
        return list.find(m => m.focused) ?? list[0] ?? null;
    }

    function secondaryMonitor() {
        const primary = root.primaryMonitor();
        const list = root.monitors.filter(m => m.name !== primary?.name);
        return list[0] ?? primary ?? null;
    }

    // ── Polling ──
    Process {
        id: displayPoller
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    const list = [];
                    for (let i = 0; i < data.length; i++) {
                        const d = data[i];
                        const modes = [];
                        for (const ms of (d.availableModes ?? [])) {
                            const match = ms.match(/(\d+)x(\d+)@([\d.]+)Hz/);
                            if (!match) continue;
                            const mode = {w: parseInt(match[1]), h: parseInt(match[2]), rate: parseFloat(match[3])};
                            if (!modes.some(o => o.w === mode.w && o.h === mode.h && Math.round(o.rate) === Math.round(mode.rate)))
                                modes.push(mode);
                        }
                        list.push({
                            name: d.name,
                            description: d.description ?? "",
                            resW: d.width, resH: d.height,
                            rate: d.refreshRate ?? 60,
                            monScale: d.scale ?? 1.0,
                            transform: d.transform ?? 0,
                            posX: d.x, posY: d.y,
                            enabled: !d.disabled,
                            focused: !!d.focused,
                            modes: modes
                        });
                        if (d.focused) root.selectedIndex = i;
                    }
                    root.monitors = list;
                    root.expandedStates = ({});
                    root.updateCommittedState();
                    if (!root.selectedSecondaryMonitor && root.secondaryMonitor())
                        root.selectedSecondaryMonitor = root.secondaryMonitor().name;
                } catch (e) {
                    console.log("[DisplaysConfig] parse error:", e);
                }
            }
        }
    }
    Timer {
        id: repollTimer
        interval: 800
        onTriggered: displayPoller.running = true
    }

    // ── Preview ──
    function updateCommittedState() {
        root.committedState = JSON.parse(JSON.stringify(root.monitors));
    }

    Timer {
        id: previewCountdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.previewCountdown -= 1;
            if (root.previewCountdown <= 0) {
                root.previewCountdown = 0;
                root.revertPreview();
            }
        }
    }

    function writeLuaFile() {
        const linesLua = [
            "-- Managed by Displays page of Settings app (Super+I).",
            ...buildMonitorSpecsLua(),
            "hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 }) -- Fallback for unconfigured monitors"
        ];
        const contentLua = linesLua.join("\n") + "\n";
        Quickshell.execDetached(["bash", "-c", `cat > '${root.monitorsLua}' << 'HYPRMON_EOF'\n${contentLua}HYPRMON_EOF`]);
    }

    function startPreview() {
        root.previewSnapshot = JSON.parse(JSON.stringify(root.committedState));
        root.writeLuaFile();
        root.applyRuntime();
        root.previewCountdown = 15;
        root.previewActive = true;
        previewCountdownTimer.restart();
    }

    function revertPreview() {
        previewCountdownTimer.stop();
        root.previewCountdown = 0;
        root.previewActive = false;
        root.monitors = JSON.parse(JSON.stringify(root.previewSnapshot));
        root.updateCommittedState();
        root.writeLuaFile();
        root.applyRuntime();
    }

    function confirmPreview() {
        previewCountdownTimer.stop();
        root.previewCountdown = 0;
        root.previewActive = false;
        root.applyAndSave();
    }

    // ── Apply ──
    function buildMonitorSpecsLua() {
        let minX = Infinity, minY = Infinity;
        for (const m of root.monitors) {
            if (!m.enabled) continue;
            minX = Math.min(minX, m.posX);
            minY = Math.min(minY, m.posY);
        }
        if (minX === Infinity) { minX = 0; minY = 0; }
        const specs = [];
        for (const m of root.monitors) {
            if (!m.enabled) {
                specs.push(`hl.monitor({ output = '${m.name}', disabled = true })`);
                continue;
            }
            let s = `hl.monitor({ output = '${m.name}', mode = '${m.resW}x${m.resH}@${m.rate.toFixed(2)}', position = '${Math.round(m.posX - minX)}x${Math.round(m.posY - minY)}', scale = ${m.monScale}`;
            s += `, transform = ${m.transform}`;
            s += " })";
            specs.push(s);
        }
        return specs;
    }

    function applyRuntime() {
        const luaSpecs = buildMonitorSpecsLua().join("; ");
        Quickshell.execDetached(["bash", "-c", `hyprctl eval "${luaSpecs}"`]);
        repollTimer.restart();
    }

    function applyAndSave() {
        root.writeLuaFile();
        root.applyRuntime();
        root.updateCommittedState();
        Quickshell.execDetached(["notify-send", "Displays", Translation.tr("Layout applied and saved")]);
    }

    property bool _pendingCommit: false

    function commit() {
        if (root._pendingCommit) return;
        root._pendingCommit = true;
        root._rev++;
        Qt.callLater(() => {
            root.monitors = root.monitors.slice();
            root._pendingCommit = false;
        });
    }

    function setMonitorProp(index, prop, value) {
        if (index < 0 || index >= root.monitors.length) return;
        const mon = Object.assign({}, root.monitors[index]);
        mon[prop] = value;
        root.monitors[index] = mon;
        root.commit();
    }

    // ── Identify ──
    function identifyMonitor(name) {
        if (!name) return;
        root.identifyingMonitorName = name;
        root.identifyOverlayVisible = true;
        identifyTimer.restart();
    }

    function identifyAllMonitors() {
        root.identifyingMonitorName = "__all__";
        root.identifyOverlayVisible = true;
        identifyTimer.restart();
    }

    Timer {
        id: identifyTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.identifyOverlayVisible = false;
            root.identifyingMonitorName = "";
        }
    }

    // ── Secondary workspace ──
    function applySecondaryWorkspace() {
        const monitor = root.selectedSecondaryMonitor || root.secondaryMonitor()?.name || "";
        if (!monitor) return;
        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch focusmonitor '${monitor}'; hyprctl dispatch workspace ${root.secondaryWorkspace}; hyprctl dispatch moveworkspacetomonitor ${root.secondaryWorkspace} '${monitor}'`]);
        repollTimer.restart();
    }

    // ── Identify overlay ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: identifyWindow
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(identifyWindow.screen)

            screen: modelData
            visible: root.identifyOverlayVisible && (root.identifyingMonitorName === "__all__" || monitor?.name === root.identifyingMonitorName)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settings-monitor-identify"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.centerIn: parent
                implicitWidth: identifyText.implicitWidth + 64
                implicitHeight: identifyText.implicitHeight + 40
                radius: Appearance.rounding.large
                color: Appearance.colors.colPrimaryContainer
                border.width: 2
                border.color: Appearance.colors.colPrimary

                StyledText {
                    id: identifyText
                    anchors.centerIn: parent
                    text: root.identifyingMonitorName === "__all__" ? (monitor?.name ?? "") : root.identifyingMonitorName
                    color: Appearance.colors.colOnPrimaryContainer
                    font.pixelSize: Appearance.font.pixelSize.title
                    font.weight: Font.Bold
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // UI
    // ══════════════════════════════════════════════════════════════════════════

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: -6
            spacing: 6

            OptionalMaterialSymbol {
                icon: "monitor"
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Connected monitors")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }
        }

        // ── Arrangement canvas ──
        ContentSection {
            icon: "grid_view"
            title: Translation.tr("Arrangement")

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Drag the screens to arrange them.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }

            ConfigRow {
                DialogButton {
                    buttonText: Translation.tr("Apply layout")
                    enabled: root.monitors.length > 0
                    onClicked: { root.writeLuaFile(); root.applyRuntime(); }
                }

                DialogButton {
                    buttonText: Translation.tr("Reset")
                    onClicked: { displayPoller.running = true; }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Drag monitors to change their position.")
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                id: canvas
                Layout.fillWidth: true
                implicitHeight: 260
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                clip: true

                readonly property var bbox: {
                    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                    for (const m of root.monitors) {
                        if (!m.enabled) continue;
                        minX = Math.min(minX, m.posX);
                        minY = Math.min(minY, m.posY);
                        maxX = Math.max(maxX, m.posX + root.logicalW(m));
                        maxY = Math.max(maxY, m.posY + root.logicalH(m));
                    }
                    if (minX === Infinity) return {x: 0, y: 0, w: 1920, h: 1080};
                    return {x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY)};
                }
                readonly property real sf: Math.min((width - 60) / bbox.w, (height - 60) / bbox.h, 0.12)
                readonly property real offX: (width - bbox.w * sf) / 2
                readonly property real offY: (height - bbox.h * sf) / 2

                function snap(idx, px, py) {
                    const m = root.monitors[idx];
                    const mw = root.logicalW(m), mh = root.logicalH(m);
                    const t = 60;
                    let sx = px, sy = py;
                    for (let j = 0; j < root.monitors.length; j++) {
                        if (j === idx || !root.monitors[j].enabled) continue;
                        const o = root.monitors[j];
                        const ox = o.posX, oy = o.posY;
                        const ow = root.logicalW(o), oh = root.logicalH(o);
                        for (const cand of [ox - mw, ox + ow, ox, ox + ow - mw, ox + ow / 2 - mw / 2])
                            if (Math.abs(px - cand) < t) { sx = cand; break; }
                        for (const cand of [oy - mh, oy + oh, oy, oy + oh - mh, oy + oh / 2 - mh / 2])
                            if (Math.abs(py - cand) < t) { sy = cand; break; }
                    }
                    return {x: Math.round(sx), y: Math.round(sy)};
                }

                Repeater {
                    model: root.monitors

                    delegate: Rectangle {
                        id: monRect
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === root.selectedIndex

                        width: root.logicalW(modelData) * canvas.sf
                        height: root.logicalH(modelData) * canvas.sf
                        radius: Appearance.rounding.unsharpenmore
                        color: selected ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                        border.width: selected ? 2 : 1
                        border.color: selected ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        opacity: modelData.enabled ? 1 : 0.45

                        Binding {
                            target: monRect; property: "x"
                            value: canvas.offX + (monRect.modelData.posX - canvas.bbox.x) * canvas.sf
                            when: !dragArea.drag.active
                        }
                        Binding {
                            target: monRect; property: "y"
                            value: canvas.offY + (monRect.modelData.posY - canvas.bbox.y) * canvas.sf
                            when: !dragArea.drag.active
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: monRect.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: monRect.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: monRect.modelData.enabled
                                    ? `${monRect.modelData.resW}x${monRect.modelData.resH} @ ${Math.round(monRect.modelData.rate)}Hz`
                                    : Translation.tr("Disabled")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            cursorShape: Qt.SizeAllCursor
                            drag.target: monRect.modelData.enabled && root.monitors.length > 1 ? monRect : undefined
                            drag.minimumX: -monRect.width / 2
                            drag.maximumX: canvas.width - monRect.width / 2
                            drag.minimumY: -monRect.height / 2
                            drag.maximumY: canvas.height - monRect.height / 2
                            onPressed: root.selectedIndex = monRect.index
                            onReleased: {
                                const px = (monRect.x - canvas.offX) / canvas.sf + canvas.bbox.x;
                                const py = (monRect.y - canvas.offY) / canvas.sf + canvas.bbox.y;
                                const snapped = canvas.snap(monRect.index, px, py);
                                if (Math.abs(snapped.x - monRect.modelData.posX) < 2
                                    && Math.abs(snapped.y - monRect.modelData.posY) < 2)
                                    return;
                                const mon = Object.assign({}, root.monitors[monRect.index]);
                                mon.posX = snapped.x;
                                mon.posY = snapped.y;
                                root.monitors[monRect.index] = mon;
                                root.commit();
                            }
                        }
                    }
                }
            }
        }

        // ── Per-monitor settings ──
        Repeater {
            model: root.monitors

            delegate: MonitorItem {
                required property var modelData
                required property int index
                monitorData: modelData
                monitorIndex: index
            }
        }

        // ── Bottom controls ──
        ConfigRow {
            DialogButton {
                buttonText: Translation.tr("Refresh")
                onClicked: displayPoller.running = true
            }

            StyledText {
                text: root.monitors.length === 1
                    ? Translation.tr("1 monitor connected")
                    : Translation.tr("%1 monitors connected").arg(root.monitors.length)
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: Translation.tr("Identify all")
                enabled: root.monitors.length > 0
                onClicked: root.identifyAllMonitors()
            }
        }

        ConfigRow {
                RippleButtonWithIcon {
                    materialIcon: "play_arrow"
                    mainText: Translation.tr("Preview")
                    onClicked: root.startPreview()
                    enabled: root.hasChanges && !root.previewActive
                    StyledToolTip {
                        text: Translation.tr("Preview the layout. Confirm or wait for auto-revert.")
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Apply and save")
                    onClicked: root.applyAndSave()
                    enabled: root.hasChanges && !root.previewActive
                    StyledToolTip {
                        text: Translation.tr("Writes monitors.lua — survives reboots and dotfile updates")
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload current state")
                    onClicked: displayPoller.running = true
                    enabled: !root.previewActive
                }
            }

            Rectangle {
                visible: root.previewActive
                Layout.fillWidth: true
                implicitHeight: 56
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHigh
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant

                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Preview active — revert in %1s").arg(root.previewCountdown)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        elide: Text.ElideRight
                    }

                    RippleButtonWithIcon {
                        materialIcon: "save"
                        mainText: Translation.tr("Apply")
                        implicitHeight: 32
                        horizontalPadding: 8
                        onClicked: root.confirmPreview()
                    }

                    RippleButtonWithIcon {
                        materialIcon: "undo"
                        mainText: Translation.tr("Revert")
                        implicitHeight: 32
                        horizontalPadding: 8
                        onClicked: root.revertPreview()
                    }
                }
            }

        // ── Secondary workspace ──
        ContentSection {
            icon: "workspaces"
            title: Translation.tr("Secondary workspace")

            ConfigRow {
                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    text: Translation.tr("Choose where the secondary monitor should land by default.")
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
            }

            ConfigRow {
                StyledText {
                    text: Translation.tr("Monitor")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    model: root.monitors.map(m => m.name)
                    currentIndex: Math.max(0, root.monitors.map(m => m.name).indexOf(root.selectedSecondaryMonitor))
                    onActivated: index => root.selectedSecondaryMonitor = root.monitors[index]?.name ?? ""
                }
            }

            ConfigRow {
                StyledText {
                    text: Translation.tr("Workspace")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledSpinBox {
                    from: 1
                    to: 100
                    value: root.secondaryWorkspace
                    onValueChanged: root.secondaryWorkspace = value
                }

                DialogButton {
                    buttonText: Translation.tr("Apply")
                    onClicked: root.applySecondaryWorkspace()
                }
            }
        }

        // ── Screensaver section ──
        ContentSection {
            icon: "auto_awesome"
            title: "Screensaver"

            ConfigSwitch {
                text: Translation.tr("Enable screensaver")
                checked: Config.options.fluid.enabled
                onCheckedChanged: Config.options.fluid.enabled = checked
                StyledToolTip {
                    text: Translation.tr("Disable to use plain dark background instead of the screensaver")
                }
            }

            ConfigSpinBox {
                visible: Config.options.fluid.enabled
                text: Translation.tr("Idle timeout before screensaver (s)")
                value: Config.options.fluid.idleTimeout
                from: 5; to: 300; stepSize: 5
                onValueChanged: Config.options.fluid.idleTimeout = value
                MouseArea {
                    id: idleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: idleHover.containsMouse
                    text: Translation.tr("How long of inactivity before the screensaver starts showing")
                }
            }

            ConfigSpinBox {
                visible: Config.options.fluid.enabled
                text: Translation.tr("Widget auto-hide delay (s)")
                value: Config.options.fluid.widgetAutoHideTimeout
                from: 3; to: 120; stepSize: 5
                onValueChanged: Config.options.fluid.widgetAutoHideTimeout = value
                MouseArea {
                    id: autoHideHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: autoHideHover.containsMouse
                    text: Translation.tr("How long after screensaver appears before toolbar/clock fade out")
                }
            }

            ContentSubsection {
                visible: Config.options.fluid.enabled
                title: "Display"

                StyledComboBox {
                    buttonIcon: "palette"
                    textRole: "displayName"
                    model: [
                        { displayName: "Original", value: 0 },
                        { displayName: "Plasma", value: 1 },
                        { displayName: "Poolside", value: 2 },
                        { displayName: "Gumdrop", value: 3 },
                        { displayName: "Silver", value: 4 },
                        { displayName: "Freedom", value: 5 }
                    ]
                    currentIndex: Config.options.fluid.colorPreset
                    onCurrentIndexChanged: {
                        Config.options.fluid.colorPreset = currentIndex
                    }
                    StyledToolTip {
                        text: Translation.tr("Line coloring preset: Original (velocity-mapped), Plasma (warm color wheel), Poolside (cool blue wheel), Gumdrop (purple-pink gradient), Silver (grayscale noise), Freedom (blue-gold)")
                    }
                }

                ConfigSpinBox {
                    text: Translation.tr("Fade duration (ms)")
                    value: Config.options.fluid.fadeDuration
                    from: 100; to: 3000; stepSize: 100
                    onValueChanged: Config.options.fluid.fadeDuration = value
                    MouseArea {
                        id: fadeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: fadeHover.containsMouse
                        text: Translation.tr("Fade in/out duration")
                    }
                }

                ConfigSwitch {
                    text: Translation.tr("Hide fluid on interaction")
                    checked: Config.options.fluid.dimOnInteraction
                    onCheckedChanged: Config.options.fluid.dimOnInteraction = checked
                    StyledToolTip {
                        text: Translation.tr("When interacting, fade fluid background out so widgets are more readable")
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.fluid.enabled
                title: "Physics"
                ConfigSpinBox {
                    icon: "water_drop"
                    text: "Viscosity (×10)"
                    value: Config.options.fluid.viscosity * 10
                    from: 1; to: 200; stepSize: 5
                    onValueChanged: Config.options.fluid.viscosity = value / 10
                    MouseArea {
                        id: viscHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: viscHover.containsMouse
                        text: Translation.tr("Fluid viscosity. Higher values make the fluid thicker, slowing diffusion")
                    }
                }
                ConfigSpinBox {
                    icon: "grain"
                    text: "Noise (×100)"
                    value: Config.options.fluid.noiseMultiplier * 100
                    from: 0; to: 200; stepSize: 5
                    onValueChanged: Config.options.fluid.noiseMultiplier = value / 100
                    MouseArea {
                        id: noiseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: noiseHover.containsMouse
                        text: Translation.tr("Turbulence driving force. Higher = more turbulent, lower = calmer")
                    }
                }
                ConfigSpinBox {
                    icon: "speed"
                    text: "Timestep (×1000)"
                    value: Config.options.fluid.timestep * 1000
                    from: 1; to: 100; stepSize: 1
                    onValueChanged: Config.options.fluid.timestep = value / 1000
                    MouseArea {
                        id: timeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: timeHover.containsMouse
                        text: Translation.tr("Simulation speed per frame. Default 0.0167 (1/60s) — best left as-is")
                    }
                }
                ConfigSpinBox {
                    icon: "blur_on"
                    text: "Dissipation (×100)"
                    value: Config.options.fluid.dissipation * 100
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: Config.options.fluid.dissipation = value / 100
                    MouseArea {
                        id: dissHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: dissHover.containsMouse
                        text: Translation.tr("Energy loss per frame. 0 = no loss (conserves energy), higher = faster decay")
                    }
                }
                ConfigSpinBox {
                    icon: "compress"
                    text: "Pressure Iterations"
                    value: Config.options.fluid.pressureIterations
                    from: 1; to: 50; stepSize: 1
                    onValueChanged: Config.options.fluid.pressureIterations = value
                    MouseArea {
                        id: pressHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: pressHover.containsMouse
                        text: Translation.tr("Pressure solver accuracy. Higher = more physically accurate but more GPU intensive. Default 19")
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.fluid.enabled
                title: "Lines"

                ConfigSpinBox {
                    icon: "straighten"
                    text: "Variance (×100)"
                    value: Config.options.fluid.lineVariance * 100
                    from: 0; to: 200; stepSize: 5
                    onValueChanged: Config.options.fluid.lineVariance = value / 100
                    MouseArea {
                        id: varHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: varHover.containsMouse
                        text: Translation.tr("How wiggly the flow lines are. Higher = more winding and chaotic")
                    }
                }
                ConfigSpinBox {
                    icon: "line_weight"
                    text: "Width (×10)"
                    value: Config.options.fluid.lineWidthMultiplier * 10
                    from: 1; to: 50; stepSize: 1
                    onValueChanged: Config.options.fluid.lineWidthMultiplier = value / 10
                    MouseArea {
                        id: widthHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: widthHover.containsMouse
                        text: Translation.tr("Line thickness multiplier. Higher = thicker lines")
                    }
                }
                ConfigSpinBox {
                    icon: "zoom_in"
                    text: "Zoom (×10)"
                    value: Config.options.fluid.zoom * 10
                    from: 5; to: 50; stepSize: 1
                    onValueChanged: Config.options.fluid.zoom = value / 10
                    MouseArea {
                        id: zoomHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: zoomHover.containsMouse
                        text: Translation.tr("Zoom level")
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.fluid.enabled
                title: "Quality"

                ConfigSpinBox {
                    icon: "speed"
                    text: "FPS Limit"
                    value: Config.options.fluid.fpsLimit
                    from: 0; to: 240; stepSize: 10
                    onValueChanged: Config.options.fluid.fpsLimit = value
                    MouseArea {
                        id: fpsHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                    StyledToolTip {
                        extraVisibleCondition: fpsHover.containsMouse
                        text: Translation.tr("Maximum frames per second. 0 = unlimited (runs as fast as your GPU can)")
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Inline component: per-monitor expandable settings card
    // ══════════════════════════════════════════════════════════════════════════

    component MonitorItem: Rectangle {
        id: itemRoot
        required property var monitorData
        required property int monitorIndex
        readonly property bool active: monitorData.focused

        property bool expanded: root.expandedStates[monitorIndex] ?? false
        onExpandedChanged: root.expandedStates[monitorIndex] = itemRoot.expanded

        Layout.fillWidth: true
        implicitHeight: monitorItemContent.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: itemRoot.expanded ? Appearance.colors.colLayer3 : mouseArea.containsMouse ? Appearance.colors.colLayer3Hover : "transparent"
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: monitorItemContent
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // ── Header row ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: itemRoot.expanded = !itemRoot.expanded
                    }

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        spacing: 10

                        MaterialSymbol {
                            text: itemRoot.active ? "desktop_windows" : "monitor"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: itemRoot.monitorData.name
                                color: Appearance.colors.colOnSurfaceVariant
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: `${itemRoot.monitorData.resW}x${itemRoot.monitorData.resH} @ ${Math.round(itemRoot.monitorData.rate)}Hz`
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Identify")
                    onClicked: root.identifyMonitor(itemRoot.monitorData.name)
                }

                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: itemRoot.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: itemRoot.expanded = !itemRoot.expanded
                    }
                }
            }

            // ── Expanded content ──
            ColumnLayout {
                visible: itemRoot.expanded
                Layout.fillWidth: true
                spacing: 10

                // Enabled
                ConfigSwitch {
                    buttonIcon: "power_settings_new"
                    text: Translation.tr("Enabled")
                    checked: itemRoot.monitorData.enabled
                    enabled: root.monitors.filter(m => m.enabled && m.name !== itemRoot.monitorData.name).length > 0
                    onCheckedChanged: {
                        if (checked !== itemRoot.monitorData.enabled)
                            root.setMonitorProp(itemRoot.monitorIndex, "enabled", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("You cannot disable the only active monitor")
                    }
                }

                // Resolution
                ContentSubsection {
                    title: Translation.tr("Resolution")
                    Layout.fillWidth: true

                    ConfigSelectionArray {
                        currentValue: `${itemRoot.monitorData.resW}x${itemRoot.monitorData.resH}`
                        onSelected: newValue => {
                            const parts = newValue.split("x");
                            const w = parseInt(parts[0]), h = parseInt(parts[1]);
                            const mon = Object.assign({}, root.monitors[itemRoot.monitorIndex]);
                            mon.resW = w;
                            mon.resH = h;
                            const rates = mon.modes.filter(m => m.w === w && m.h === h).map(m => m.rate);
                            if (rates.length > 0)
                                mon.rate = Math.max(...rates);
                            root.monitors[itemRoot.monitorIndex] = mon;
                            root.commit();
                        }
                        options: {
                            const seen = [];
                            for (const m of itemRoot.monitorData.modes) {
                                const v = `${m.w}x${m.h}`;
                                if (!seen.some(o => o.value === v))
                                    seen.push({displayName: v, value: v});
                            }
                            seen.sort((a, b) => parseInt(b.value) - parseInt(a.value));
                            return seen;
                        }
                    }
                }

                // Refresh rate
                ContentSubsection {
                    title: Translation.tr("Refresh rate")
                    Layout.fillWidth: true

                    ConfigSelectionArray {
                        currentValue: Math.round(itemRoot.monitorData.rate)
                        onSelected: newValue => {
                            const exact = itemRoot.monitorData.modes.find(m =>
                                m.w === itemRoot.monitorData.resW && m.h === itemRoot.monitorData.resH && Math.round(m.rate) === newValue);
                            root.setMonitorProp(itemRoot.monitorIndex, "rate", exact ? exact.rate : newValue);
                        }
                        options: {
                            const opts = [];
                            for (const m of itemRoot.monitorData.modes) {
                                if (m.w !== itemRoot.monitorData.resW || m.h !== itemRoot.monitorData.resH) continue;
                                const r = Math.round(m.rate);
                                if (!opts.some(o => o.value === r))
                                    opts.push({displayName: `${r} Hz`, value: r});
                            }
                            opts.sort((a, b) => b.value - a.value);
                            return opts;
                        }
                    }
                }

                // Scale
                ContentSubsection {
                    title: Translation.tr("Scale")
                    Layout.fillWidth: true

                    ConfigSelectionArray {
                        currentValue: itemRoot.monitorData.monScale
                        onSelected: newValue => root.setMonitorProp(itemRoot.monitorIndex, "monScale", newValue)
                        options: {
                            const std = [1, 1.25, 1.5, 1.75, 2];
                            const cur = itemRoot.monitorData.monScale;
                            const opts = std.map(s => ({displayName: `${Math.round(s * 100)}%`, value: s}));
                            if (!std.includes(cur))
                                opts.unshift({displayName: `${Math.round(cur * 100)}%`, value: cur});
                            return opts;
                        }
                    }
                }

                // Rotation
                ContentSubsection {
                    title: Translation.tr("Rotation")
                    Layout.fillWidth: true

                    ConfigSelectionArray {
                        currentValue: itemRoot.monitorData.transform
                        onSelected: newValue => root.setMonitorProp(itemRoot.monitorIndex, "transform", newValue)
                        options: [
                            {displayName: Translation.tr("Normal"), icon: "stay_current_landscape", value: 0},
                            {displayName: "90°", icon: "rotate_90_degrees_cw", value: 1},
                            {displayName: "180°", icon: "sync", value: 2},
                            {displayName: "270°", icon: "rotate_90_degrees_ccw", value: 3}
                        ]
                    }
                }

                // Position
                ContentSubsection {
                    title: Translation.tr("Position")
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: "open_with"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: "X"
                            color: Appearance.colors.colOnSecondaryContainer
                        }

                        MaterialTextField {
                            id: posXField
                            Layout.preferredWidth: 82
                            Layout.preferredHeight: 44
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            text: `${itemRoot.monitorData.posX}`
                            validator: IntValidator {
                                bottom: -20000
                                top: 20000
                            }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onAccepted: focus = false
                            onEditingFinished: {
                                const value = parseInt(text);
                                if (!isNaN(value)) {
                                    const mon = Object.assign({}, root.monitors[itemRoot.monitorIndex]);
                                    mon.posX = value;
                                    root.monitors[itemRoot.monitorIndex] = mon;
                                    root.commit();
                                }
                            }
                        }

                        StyledText {
                            text: "Y"
                            color: Appearance.colors.colOnSecondaryContainer
                        }

                        MaterialTextField {
                            id: posYField
                            Layout.preferredWidth: 82
                            Layout.preferredHeight: 44
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            text: `${itemRoot.monitorData.posY}`
                            validator: IntValidator {
                                bottom: -20000
                                top: 20000
                            }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onAccepted: focus = false
                            onEditingFinished: {
                                const value = parseInt(text);
                                if (!isNaN(value)) {
                                    const mon = Object.assign({}, root.monitors[itemRoot.monitorIndex]);
                                    mon.posY = value;
                                    root.monitors[itemRoot.monitorIndex] = mon;
                                    root.commit();
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Position in logical pixels")
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}

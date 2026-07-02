import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    // Persistencia: monitors.lua está en la lista de exclusiones del instalador,
    // así que las actualizaciones del dotfile no lo tocan
    readonly property string monitorsLua: FileUtils.trimFileProtocol(`${Directories.config}/hypr/monitors.lua`)

    // Lista de monitores: [{name, description, resW, resH, rate, monScale, transform, posX, posY, enabled, modes}]
    // posX/posY en píxeles lógicos (como hyprctl). modes: [{w, h, rate}]
    property var monitors: []
    property int selectedIndex: 0
    readonly property var selMon: (monitors.length > 0 && selectedIndex < monitors.length) ? monitors[selectedIndex] : null

    readonly property bool hasChanges: JSON.stringify(root.monitors) !== JSON.stringify(root.committedState)

    function commit() {
        root.monitors = root.monitors.slice();
    }

    function logicalW(m) {
        const w = (m.transform % 2 === 1) ? m.resH : m.resW;
        return w / m.monScale;
    }
    function logicalH(m) {
        const h = (m.transform % 2 === 1) ? m.resW : m.resH;
        return h / m.monScale;
    }

    // ── Lectura del estado real ────────────────────────────────────────────
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
                            modes: modes
                        });
                        if (d.focused) root.selectedIndex = i;
                    }
                    root.monitors = list;
                    root.updateCommittedState();
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

    // ── Preview countdown ───────────────────────────────────────────────────
    property int previewCountdown: 0
    property bool previewActive: false
    property var previewSnapshot: []
    // Estado "committed" = última vez que se aplicó/guardó/confirmó/polleó
    property var committedState: []

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

    function startPreview() {
        root.previewSnapshot = JSON.parse(JSON.stringify(root.committedState));
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
        root.applyRuntime();
    }

    function confirmPreview() {
        previewCountdownTimer.stop();
        root.previewCountdown = 0;
        root.previewActive = false;
        root.applyAndSave();
    }

    // ── Aplicar y guardar ──────────────────────────────────────────────────
    // Normaliza el origen a (0,0) y devuelve llamadas hl.monitor({...})
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

    // Solo en caliente: si algo sale mal, hyprctl reload restaura lo guardado
    function applyRuntime() {
        const luaSpecs = buildMonitorSpecsLua().join("; ");
        Quickshell.execDetached(["bash", "-c", `hyprctl eval "${luaSpecs}"`]);
        repollTimer.restart();
    }

    // Escribe monitors.lua; Hyprland lo recarga solo (y así también se aplica)
    function applyAndSave() {
        const linesLua = [
            "-- Managed by Displays page of Settings app (Super+I).",
            ...buildMonitorSpecsLua(),
            "hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 }) -- Fallback for unconfigured monitors"
        ];
        const contentLua = linesLua.join("\n") + "\n";

        Quickshell.execDetached(["bash", "-c", `cat > '${root.monitorsLua}' << 'HYPRMON_EOF'\n${contentLua}HYPRMON_EOF`]);

        applyRuntime();
        root.updateCommittedState();

        Quickshell.execDetached(["notify-send", "Displays", Translation.tr("Layout applied and saved")]);
    }

    function setMonProp(prop, value) {
        if (!root.selMon) return;
        const mon = Object.assign({}, root.monitors[root.selectedIndex]);
        mon[prop] = value;
        root.monitors[root.selectedIndex] = mon;
        root.commit();
    }

    // ── Lienzo: disposición de monitores ───────────────────────────────────
    ContentSection {
        icon: "grid_view"
        title: Translation.tr("Arrangement")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Drag the screens to arrange them. Click one to edit it below.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: canvas
            Layout.fillWidth: true
            implicitHeight: 240
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            // Caja envolvente del layout en píxeles lógicos
            readonly property var bbox: {
                let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                for (const m of root.monitors) {
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

            // Imán: pega los bordes del monitor arrastrado a los de los demás
            function snap(idx, px, py) {
                const m = root.monitors[idx];
                const mw = root.logicalW(m), mh = root.logicalH(m);
                const t = 60; // umbral en píxeles lógicos
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
                            // Un clic sin arrastre no cuenta como cambio
                            if (Math.abs(snapped.x - monRect.modelData.posX) < 2 //
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

    // ── Monitor seleccionado ───────────────────────────────────────────────
    ContentSection {
        visible: root.selMon !== null
        icon: "monitor"
        title: root.selMon ? root.selMon.name : ""

        StyledText {
            Layout.fillWidth: true
            visible: (root.selMon?.description ?? "") !== ""
            text: root.selMon?.description ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        ConfigSwitch {
            buttonIcon: "power_settings_new"
            text: Translation.tr("Enabled")
            checked: root.selMon?.enabled ?? true
            enabled: !(root.selMon?.enabled ?? true) || root.monitors.filter(m => m.enabled).length > 1
            onCheckedChanged: {
                if (root.selMon && checked !== root.selMon.enabled)
                    root.setMonProp("enabled", checked);
            }
            StyledToolTip {
                text: Translation.tr("You cannot disable the only active monitor")
            }
        }

        ContentSubsection {
            title: Translation.tr("Resolution")
            ConfigSelectionArray {
                currentValue: root.selMon ? `${root.selMon.resW}x${root.selMon.resH}` : ""
                onSelected: newValue => {
                    const parts = newValue.split("x");
                    const w = parseInt(parts[0]), h = parseInt(parts[1]);
                    const mon = Object.assign({}, root.monitors[root.selectedIndex]);
                    mon.resW = w;
                    mon.resH = h;
                    const rates = mon.modes.filter(m => m.w === w && m.h === h).map(m => m.rate);
                    if (rates.length > 0)
                        mon.rate = Math.max(...rates);
                    root.monitors[root.selectedIndex] = mon;
                    root.commit();
                }
                options: {
                    if (!root.selMon) return [];
                    const seen = [];
                    for (const m of root.selMon.modes) {
                        const v = `${m.w}x${m.h}`;
                        if (!seen.some(o => o.value === v))
                            seen.push({displayName: v, value: v});
                    }
                    seen.sort((a, b) => parseInt(b.value) - parseInt(a.value));
                    return seen;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Refresh rate")
            ConfigSelectionArray {
                currentValue: root.selMon ? Math.round(root.selMon.rate) : 60
                onSelected: newValue => {
                    const exact = root.selMon.modes.find(m => //
                        m.w === root.selMon.resW && m.h === root.selMon.resH && Math.round(m.rate) === newValue);
                    root.setMonProp("rate", exact ? exact.rate : newValue);
                }
                options: {
                    if (!root.selMon) return [];
                    const opts = [];
                    for (const m of root.selMon.modes) {
                        if (m.w !== root.selMon.resW || m.h !== root.selMon.resH) continue;
                        const r = Math.round(m.rate);
                        if (!opts.some(o => o.value === r))
                            opts.push({displayName: `${r} Hz`, value: r});
                    }
                    opts.sort((a, b) => b.value - a.value);
                    return opts;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Scale")
            ConfigSelectionArray {
                currentValue: root.selMon?.monScale ?? 1
                onSelected: newValue => root.setMonProp("monScale", newValue)
                options: {
                    const std = [1, 1.25, 1.5, 1.75, 2];
                    const cur = root.selMon?.monScale ?? 1;
                    const opts = std.map(s => ({displayName: `${Math.round(s * 100)}%`, value: s}));
                    if (!std.includes(cur))
                        opts.unshift({displayName: `${Math.round(cur * 100)}%`, value: cur});
                    return opts;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Rotation")
            ConfigSelectionArray {
                currentValue: root.selMon?.transform ?? 0
                onSelected: newValue => root.setMonProp("transform", newValue)
                options: [
                    {displayName: Translation.tr("Normal"), icon: "stay_current_landscape", value: 0},
                    {displayName: "90°", icon: "rotate_90_degrees_cw", value: 1},
                    {displayName: "180°", icon: "sync", value: 2},
                    {displayName: "270°", icon: "rotate_90_degrees_ccw", value: 3}
                ]
            }
        }
    }

    // ── Acciones ───────────────────────────────────────────────────────────
    ContentSection {
        icon: "rocket_launch"
        title: Translation.tr("Apply")

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

        // ── Preview confirmation overlay ────────────────────────────────────
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
    }

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

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "components" as DisplaysComponents
ContentPage {
    id: root
    forceWidth: true
    property string selectedMonitorName: ""
    property var pendingSettings: ({})
    property var pendingPositions: ({})
    property var confirmedSettings: ({})
    property var confirmedPositions: ({})
    property var rollbackSettings: ({})
    property var rollbackPositions: ({})
    // Última frequência confirmada para cada resolução
    // de cada monitor. Exemplo:
    // {
    //     "DP-2": {
    //         "1920x1080": "143.98",
    //         "720x480": "59.94"
    //     }
    // }
    property var refreshRateHistory: ({})
    property bool refreshRateHistoryInitialized: false
    property var transactionOriginSettings: ({})
    property bool applyScheduled: false
    property string localError: ""
    readonly property var monitors: HyprlandData.monitors
    readonly property var selectedMonitor: {
        return monitors.find(
            monitor => monitor.name === selectedMonitorName
        ) ?? monitors[0] ?? null;
    }
    readonly property var selectedSettings: {
        if (!selectedMonitor)
            return null;
        const name = selectedMonitor.name;
        return pendingSettings[name]
            ?? confirmedSettings[name]
            ?? defaultSettings(selectedMonitor);
    }
    readonly property bool hasPendingChanges:
        Object.keys(pendingSettings).length > 0
        || Object.keys(pendingPositions).length > 0
    readonly property bool editingLocked:
        DisplayManager.busy || DisplayManager.confirming
    readonly property var previewMonitors: monitors.map(monitor => {
        const name = monitor.name;
        const settings = pendingSettings[name]
            ?? confirmedSettings[name];
        const position = pendingPositions[name]
            ?? confirmedPositions[name];
        const resolution = settings
            ? settings.resolution.split("x")
            : [monitor.width, monitor.height];
        return Object.assign({}, monitor, {
            width: Number(resolution[0]),
            height: Number(resolution[1]),
            scale: settings
                ? Number(settings.scale)
                : monitor.scale,
            transform: settings
                ? Number(settings.transform)
                : monitor.transform,
            refreshRate: settings
                ? Number(settings.refreshRate)
                : monitor.refreshRate,
            x: position ? position.x : monitor.x,
            y: position ? position.y : monitor.y
        });
    })
    function ensureSelection() {
        if (monitors.length === 0) {
            selectedMonitorName = "";
            return;
        }
        if (!monitors.some(
            monitor => monitor.name === selectedMonitorName
        )) {
            selectedMonitorName = monitors[0].name;
        }
    }
    function defaultSettings(monitor) {
        return {
            resolution: `${monitor.width}x${monitor.height}`,
            refreshRate: Number(monitor.refreshRate).toFixed(2),
            scale: Number(monitor.scale).toFixed(2),
            transform: String(monitor.transform ?? 0)
        };
    }
    function baselineSettings(monitor) {
        if (!monitor)
            return null;
        return confirmedSettings[monitor.name]
            ?? defaultSettings(monitor);
    }
    function baselinePosition(monitor) {
        if (!monitor)
            return null;
        return confirmedPositions[monitor.name]
            ?? {
                x: monitor.x,
                y: monitor.y
            };
    }
    // Registra a frequência somente depois que ela foi
    // efetivamente confirmada pelo usuário.
    function rememberRefreshRate(name, resolution, rate) {
        if (!name || !resolution)
            return;
        const numericRate = Number(rate);
        if (!Number.isFinite(numericRate))
            return;
        const history = Object.assign({}, refreshRateHistory);
        const monitorHistory = Object.assign(
            {},
            history[name] ?? {}
        );
        monitorHistory[resolution] =
            numericRate.toFixed(2);
        history[name] = monitorHistory;
        refreshRateHistory = history;
    }
    // Registra a configuração atual de cada monitor
    // apenas quando ainda não existe histórico para
    // aquela combinação de monitor e resolução.
    function initializeRefreshRateHistory() {
        // Inicializa apenas uma vez, com os monitores realmente disponíveis.
        // Atualizações assíncronas não podem registrar frequências transitórias.
        if (refreshRateHistoryInitialized || monitors.length === 0)
            return;
        if (DisplayManager.busy || DisplayManager.confirming || hasPendingChanges)
            return;
        for (const monitor of monitors) {
            const settings = baselineSettings(monitor);
            if (settings)
                rememberRefreshRate(monitor.name, settings.resolution,
                                    settings.refreshRate);
        }
        refreshRateHistoryInitialized = true;
    }
    function logicalWidth(monitor) {
        const rotated = Number(monitor.transform) % 2 !== 0;
        return (rotated ? monitor.height : monitor.width)
            / Math.max(0.01, Number(monitor.scale));
    }
    function logicalHeight(monitor) {
        const rotated = Number(monitor.transform) % 2 !== 0;
        return (rotated ? monitor.width : monitor.height)
            / Math.max(0.01, Number(monitor.scale));
    }
    function rangesOverlap(a1, a2, b1, b2) {
        return a1 < b2 && a2 > b1;
    }
    function repositionNeighbors(oldMonitor, newMonitor) {
        if (!oldMonitor || !newMonitor)
            return;
        const oldWidth = logicalWidth(oldMonitor);
        const oldHeight = logicalHeight(oldMonitor);
        const deltaWidth =
            logicalWidth(newMonitor) - oldWidth;
        const deltaHeight =
            logicalHeight(newMonitor) - oldHeight;
        if (Math.abs(deltaWidth) < 0.01
            && Math.abs(deltaHeight) < 0.01) {
            return;
        }
        const positions = Object.assign({}, pendingPositions);
        const oldRight = oldMonitor.x + oldWidth;
        const oldBottom = oldMonitor.y + oldHeight;
        for (const monitor of previewMonitors) {
            if (monitor.name === oldMonitor.name)
                continue;
            let x = monitor.x;
            let y = monitor.y;
            const verticallyRelated = rangesOverlap(
                oldMonitor.y,
                oldBottom,
                y,
                y + logicalHeight(monitor)
            );
            const horizontallyRelated = rangesOverlap(
                oldMonitor.x,
                oldRight,
                x,
                x + logicalWidth(monitor)
            );
            if (verticallyRelated && x >= oldRight - 1)
                x += deltaWidth;
            if (horizontallyRelated && y >= oldBottom - 1)
                y += deltaHeight;
            if (Math.abs(x - monitor.x) > 0.01
                || Math.abs(y - monitor.y) > 0.01) {
                positions[monitor.name] = {
                    x: Math.round(x),
                    y: Math.round(y)
                };
            }
        }
        pendingPositions = positions;
    }
    function scheduleApply() {
        if (editingLocked || applyScheduled)
            return;
        applyScheduled = true;
        Qt.callLater(root.flushScheduledApply);
    }
    function flushScheduledApply() {
        applyScheduled = false;
        if (editingLocked || !hasPendingChanges)
            return;
        applyChanges();
    }
    function updateSetting(key, value) {
        if (!selectedMonitor || editingLocked)
            return;
        const name = selectedMonitor.name;
        const previousPreview = previewMonitors.find(
            monitor => monitor.name === name
        );
        const current = Object.assign({}, selectedSettings);
        current[key] = value;
        const baseline = baselineSettings(selectedMonitor);
        const updated = Object.assign({}, pendingSettings);
        const changed = Object.keys(baseline).some(
            setting => String(current[setting])
                !== String(baseline[setting])
        );
        if (changed)
            updated[name] = current;
        else
            delete updated[name];
        const resolution = current.resolution.split("x");
        const nextPreview = Object.assign({}, previousPreview, {
            width: Number(resolution[0]),
            height: Number(resolution[1]),
            scale: Number(current.scale),
            transform: Number(current.transform)
        });
        if (key === "resolution"
            || key === "scale"
            || key === "transform") {
            repositionNeighbors(previousPreview, nextPreview);
        }
        pendingSettings = updated;
        localError = "";
        scheduleApply();
    }
    function updatePositions(positions) {
        if (editingLocked)
            return;
        const updated = Object.assign({}, pendingPositions);
        for (const name of Object.keys(positions)) {
            const position = positions[name];
            if (!position)
                continue;
            const monitor = monitors.find(
                item => item.name === name
            );
            if (!monitor)
                continue;
            const x = Math.round(Number(position.x));
            const y = Math.round(Number(position.y));
            if (!Number.isFinite(x) || !Number.isFinite(y))
                continue;
            const baseline = baselinePosition(monitor);
            if (x === Math.round(baseline.x)
                && y === Math.round(baseline.y)) {
                delete updated[name];
            } else {
                updated[name] = {
                    x: x,
                    y: y
                };
            }
        }
        pendingPositions = updated;
        localError = "";
        scheduleApply();
    }
    function resetChanges() {
        pendingSettings = {};
        pendingPositions = {};
        applyScheduled = false;
        localError = "";
    }
    function settingsMatch(monitor, expected) {
        if (!monitor || !expected)
            return false;
        if (`${monitor.width}x${monitor.height}`
            !== expected.resolution) {
            return false;
        }
        if (Math.abs(
            Number(monitor.refreshRate)
            - Number(expected.refreshRate)
        ) > 0.15) {
            return false;
        }
        if (Math.abs(
            Number(monitor.scale)
            - Number(expected.scale)
        ) > 0.01) {
            return false;
        }
        return Number(monitor.transform)
            === Number(expected.transform);
    }
    function positionMatches(monitor, expected) {
        if (!monitor || !expected)
            return false;
        return Math.abs(
            Number(monitor.x) - Number(expected.x)
        ) <= 1
        && Math.abs(
            Number(monitor.y) - Number(expected.y)
        ) <= 1;
    }
    function reconcileConfirmedState() {
        const settings = Object.assign({}, confirmedSettings);
        const positions = Object.assign({}, confirmedPositions);
        let settingsChanged = false;
        let positionsChanged = false;
        for (const name of Object.keys(settings)) {
            const monitor = monitors.find(
                item => item.name === name
            );
            if (settingsMatch(monitor, settings[name])) {
                delete settings[name];
                settingsChanged = true;
            }
        }
        for (const name of Object.keys(positions)) {
            const monitor = monitors.find(
                item => item.name === name
            );
            if (positionMatches(monitor, positions[name])) {
                delete positions[name];
                positionsChanged = true;
            }
        }
        if (settingsChanged)
            confirmedSettings = settings;
        if (positionsChanged)
            confirmedPositions = positions;
    }
    function acceptConfirmedChanges() {
        const settings = Object.assign({}, confirmedSettings);
        const positions = Object.assign({}, confirmedPositions);
        for (const name of Object.keys(pendingSettings)) {
            settings[name] = Object.assign(
                {},
                pendingSettings[name]
            );
        }
        for (const name of Object.keys(pendingPositions)) {
            positions[name] = Object.assign(
                {},
                pendingPositions[name]
            );
        }
        // Confirma primeiro a frequência da resolução de origem.
        // Ela deve continuar disponível no histórico após a troca.
        for (const name of Object.keys(pendingSettings)) {
            const origin = transactionOriginSettings[name];
            const destination = pendingSettings[name];
            if (origin && origin.resolution !== destination.resolution)
                rememberRefreshRate(name, origin.resolution,
                                    origin.refreshRate);
            rememberRefreshRate(name, destination.resolution,
                                destination.refreshRate);
        }
        transactionOriginSettings = {};
        confirmedSettings = settings;
        confirmedPositions = positions;
        rollbackSettings = {};
        rollbackPositions = {};
        resetChanges();
        reconcileConfirmedState();
    }
    function restorePreviousPreview() {
        transactionOriginSettings = {};
        confirmedSettings = Object.assign({}, rollbackSettings);
        confirmedPositions = Object.assign({}, rollbackPositions);
        rollbackSettings = {};
        rollbackPositions = {};
        // Não modifica refreshRateHistory:
        // uma configuração revertida não é confirmada.
        resetChanges();
    }
    function availableModes(monitor) {
        if (!monitor)
            return [];
        const modes = Array.isArray(monitor.availableModes)
            ? monitor.availableModes : [];
        const parsed = [];
        for (const mode of modes) {
            const match = String(mode).match(
                /(\d+)x(\d+)@([\d.]+)Hz?/
            );
            if (!match)
                continue;
            parsed.push({
                resolution: `${match[1]}x${match[2]}`,
                refreshRate: Number(match[3]).toFixed(2)
            });
        }
        parsed.push({
            resolution: `${monitor.width}x${monitor.height}`,
            refreshRate: Number(monitor.refreshRate).toFixed(2)
        });
        return parsed;
    }
    function resolutionOptions(monitor) {
        if (!monitor)
            return [];
        const resolutions = [
            ...new Set(
                availableModes(monitor).map(
                    mode => mode.resolution
                )
            )
        ];
        return resolutions.map(resolution => ({
            displayName: resolution.replace("x", " × "),
            icon: "aspect_ratio",
            value: resolution
        }));
    }
    // Frequências suportadas, ordenadas da maior
    // para a menor.
    function refreshRateOptions(monitor, resolution) {
        if (!monitor)
            return [];
        const rates = [
            ...new Set(
                availableModes(monitor)
                    .filter(mode =>
                        mode.resolution === resolution
                    )
                    .map(mode => mode.refreshRate)
            )
        ];
        rates.sort(
            (a, b) => Number(b) - Number(a)
        );
        return rates.map(rate => ({
            displayName: `${rate} Hz`,
            icon: "speed",
            value: rate
        }));
    }
    // Seleciona a frequência numericamente mais próxima.
    // Em empates, prefere a frequência maior.
    function closestRefreshRate(monitor, resolution, currentRate) {
        const options = refreshRateOptions(
            monitor,
            resolution
        );
        if (options.length === 0)
            return null;
        const target = Number(currentRate);
        if (!Number.isFinite(target))
            return options[0].value;
        let bestRate = options[0].value;
        let bestDistance = Math.abs(
            Number(bestRate) - target
        );
        for (const option of options) {
            const rate = Number(option.value);
            const distance = Math.abs(rate - target);
            if (distance < bestDistance - 0.000001) {
                bestRate = option.value;
                bestDistance = distance;
            } else if (
                Math.abs(distance - bestDistance) <= 0.000001
                && rate > Number(bestRate)
            ) {
                bestRate = option.value;
            }
        }
        return bestRate;
    }
    // Ao retornar a uma resolução já utilizada,
    // restaura a última frequência confirmada nela.
    // Se ainda não existe histórico, escolhe a
    // frequência suportada mais próxima da atual.
    function preferredRefreshRate(
        monitor,
        resolution,
        currentRate
    ) {
        if (!monitor)
            return null;
        const monitorHistory =
            refreshRateHistory[monitor.name] ?? {};
        const rememberedRate =
            monitorHistory[resolution];
        if (rememberedRate !== undefined) {
            const options = refreshRateOptions(
                monitor,
                resolution
            );
            const rememberedOption = options.find(
                option => Math.abs(
                    Number(option.value)
                    - Number(rememberedRate)
                ) < 0.05
            );
            if (rememberedOption)
                return rememberedOption.value;
        }
        return closestRefreshRate(
            monitor,
            resolution,
            currentRate
        );
    }
    function scaleOptions(monitor) {
        const values = [
            0.75, 1.00, 1.25, 1.50,
            1.75, 2.00, 2.50, 3.00
        ];
        if (monitor) {
            const current = Number(monitor.scale);
            if (!values.some(value =>
                Math.abs(value - current) < 0.001
            )) {
                values.push(current);
            }
        }
        values.sort((a, b) => a - b);
        return values.map(value => ({
            displayName: `${Math.round(value * 100)}%`,
            icon: "zoom_in",
            value: value.toFixed(2)
        }));
    }
    function transformOptions() {
        return [
            {
                displayName: "Normal (0°)",
                icon: "crop_landscape",
                value: "0"
            },
            {
                displayName: "90°",
                icon: "screen_rotation",
                value: "1"
            },
            {
                displayName: "180°",
                icon: "screen_rotation",
                value: "2"
            },
            {
                displayName: "270°",
                icon: "screen_rotation",
                value: "3"
            }
        ];
    }
    function exactMode(monitor, resolution, rate) {
        const candidates = Array.isArray(monitor.availableModes)
            ? monitor.availableModes : [];
        const target = Number(rate);
        let best = null;
        let distance = Infinity;
        for (const entry of candidates) {
            const match = String(entry).match(
                /^(\d+x\d+)@([\d.]+)Hz?$/
            );
            if (!match || match[1] !== resolution)
                continue;
            const delta = Math.abs(
                Number(match[2]) - target
            );
            if (delta < distance) {
                distance = delta;
                best = String(entry).replace(/Hz$/, "");
            }
        }
        if (best === null || distance > 0.05)
            return null;
        return best;
    }
    function buildTargets() {
        const targets = [];
        for (const monitor of previewMonitors) {
            const original = monitors.find(
                item => item.name === monitor.name
            );
            if (!original)
                return null;
            const settings = pendingSettings[monitor.name]
                ?? confirmedSettings[monitor.name]
                ?? defaultSettings(original);
            const mode = exactMode(
                original,
                settings.resolution,
                settings.refreshRate
            );
            if (!mode)
                return null;
            targets.push({
                name: monitor.name,
                mode: mode,
                x: Math.round(Number(monitor.x)),
                y: Math.round(Number(monitor.y)),
                scale: Number(settings.scale),
                transform: Number(settings.transform)
            });
        }
        return targets;
    }
    function applyChanges() {
        if (!hasPendingChanges || editingLocked)
            return;
        const targets = buildTargets();
        if (!targets) {
            resetChanges();
            localError = Translation.tr(
                "Could not find a supported display mode."
            );
            return;
        }
        const previousSettings = {};
        const previousPositions = {};
        for (const monitor of monitors) {
            previousSettings[monitor.name] =
                Object.assign({}, baselineSettings(monitor));
            previousPositions[monitor.name] =
                Object.assign({}, baselinePosition(monitor));
        }
        transactionOriginSettings = previousSettings;
        rollbackSettings = previousSettings;
        rollbackPositions = previousPositions;
        localError = "";
        DisplayManager.apply(targets);
    }
    Component.onCompleted: {
        ensureSelection();
        initializeRefreshRateHistory();
    }
    onMonitorsChanged: {
        ensureSelection();
        reconcileConfirmedState();
        // Somente o primeiro estado estável pode inicializar o histórico.
        // Depois disso, apenas confirmações do usuário podem atualizá-lo.
        initializeRefreshRateHistory();
    }
    Connections {
        target: DisplayManager
        function onConfirmed() {
            root.acceptConfirmedChanges();
        }
        function onReverted() {
            root.restorePreviousPreview();
        }
        function onFailed(message) {
            root.restorePreviousPreview();
            root.localError = message;
        }
    }
    DisplaysComponents.MonitorIdentifier {
        id: monitorIdentifier
        monitors: root.monitors
    }
    ContentSection {
        icon: "desktop_windows"
        title: Translation.tr("Displays")
        ContentSubsection {
            title: Translation.tr("Display arrangement")
            DisplaysComponents.MonitorArrangement {
                monitors: root.previewMonitors
                selectedMonitorName:
                    root.selectedMonitor?.name ?? ""
                onMonitorSelected: name => {
                    root.selectedMonitorName = name;
                }
                onLayoutChanged: positions => {
                    root.updatePositions(positions);
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Identify displays")
            ConfigSelectionArray {
                currentValue: ""
                options: [{
                    displayName: Translation.tr(
                        "Identify monitors"
                    ),
                    icon: "monitor",
                    value: "identify"
                }]
                onSelected: newValue => {
                    if (newValue === "identify")
                        monitorIdentifier.identify();
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Selected display")
            visible: root.selectedMonitor !== null
            ConfigSelectionArray {
                currentValue:
                    root.selectedMonitor?.name ?? ""
                options: root.monitors.map(monitor => ({
                    displayName: monitor.name,
                    icon: "monitor",
                    value: monitor.name
                }))
                onSelected: newValue => {
                    root.selectedMonitorName = newValue;
                }
            }
        }
    }
    ContentSection {
        icon: "tune"
        title: Translation.tr("Display configuration")
        visible: root.selectedMonitor !== null
        ContentSubsection {
            title: Translation.tr("Resolution")
            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.resolution ?? ""
                options: root.resolutionOptions(
                    root.selectedMonitor
                )
                onSelected: newValue => {
                    if (root.editingLocked)
                        return;
                    const previousRate =
                        root.selectedSettings?.refreshRate ?? "";
                    // Consulta o histórico antes de alterar
                    // a resolução selecionada.
                    const nextRate = root.preferredRefreshRate(
                        root.selectedMonitor,
                        newValue,
                        previousRate
                    );
                    root.updateSetting(
                        "resolution",
                        newValue
                    );
                    // As alterações de resolução e frequência
                    // são agrupadas em uma única aplicação.
                    if (nextRate !== null
                        && nextRate !== previousRate) {
                        root.updateSetting(
                            "refreshRate",
                            nextRate
                        );
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Refresh rate")
            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.refreshRate ?? ""
                options: root.refreshRateOptions(
                    root.selectedMonitor,
                    root.selectedSettings?.resolution ?? ""
                )
                onSelected: newValue => {
                    root.updateSetting(
                        "refreshRate",
                        newValue
                    );
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Scale")
            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.scale ?? ""
                options: root.scaleOptions(
                    root.selectedMonitor
                )
                onSelected: newValue => {
                    root.updateSetting(
                        "scale",
                        newValue
                    );
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Orientation")
            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.transform ?? "0"
                options: root.transformOptions()
                onSelected: newValue => {
                    root.updateSetting(
                        "transform",
                        newValue
                    );
                }
            }
        }
    }
    ContentSection {
        icon: "error_outline"
        title: Translation.tr("Display error")
        visible: root.localError !== ""
        ContentSubsection {
            StyledText {
                text: root.localError
                wrapMode: Text.WordWrap
            }
        }
    }
    Controls.Popup {
        id: confirmationPopup
        parent: Controls.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(
            380,
            parent ? parent.width - 32 : 380
        )
        modal: true
        focus: true
        closePolicy: Controls.Popup.NoAutoClose
        visible: DisplayManager.confirming
        padding: 24
        background: Rectangle {
            radius: Appearance.rounding.large
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
        }
        contentItem: ColumnLayout {
            spacing: 16
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr(
                    "Confirm display changes"
                )
                font.pixelSize: 20
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr(
                    "Keep these display settings?"
                )
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: String(
                    DisplayManager.secondsRemaining
                )
                font.pixelSize: 42
                font.weight: Font.Bold
                color: Appearance.m3colors.m3primary
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Translation.tr(
                    "The previous settings will be restored automatically when the countdown ends."
                )
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Controls.Button {
                    Layout.fillWidth: true
                    enabled: DisplayManager.confirming
                        && !DisplayManager.busy
                    onClicked: DisplayManager.rollback()
                    contentItem: StyledText {
                        text: Translation.tr(
                            "Revert changes"
                        )
                        horizontalAlignment:
                            Text.AlignHCenter
                        verticalAlignment:
                            Text.AlignVCenter
                        color:
                            Appearance.m3colors.m3onSurface
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.normal
                        color:
                            Appearance.m3colors.m3surfaceContainerLow
                        border.width: 1
                        border.color:
                            Appearance.m3colors.m3outlineVariant
                    }
                }
                Controls.Button {
                    Layout.fillWidth: true
                    enabled: DisplayManager.confirming
                        && !DisplayManager.busy
                    onClicked: DisplayManager.keep()
                    contentItem: StyledText {
                        text: Translation.tr(
                            "Keep changes"
                        )
                        horizontalAlignment:
                            Text.AlignHCenter
                        verticalAlignment:
                            Text.AlignVCenter
                        color:
                            Appearance.m3colors.m3onPrimaryContainer
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.normal
                        color:
                            Appearance.m3colors.m3primaryContainer
                    }
                }
            }
        }
    }
}

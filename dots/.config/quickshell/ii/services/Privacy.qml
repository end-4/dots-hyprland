pragma Singleton
pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity.
 */
Singleton {
    id: root

    readonly property bool micWatched: Config.options.bar.indicators.mic.showIndicator
    readonly property bool cameraWatched: Config.options.bar.indicators.camera.showIndicator
    readonly property bool screenWatched: Config.options.bar.indicators.screen.showIndicator
    readonly property bool videoWatched: root.cameraWatched || root.screenWatched

    readonly property list<var> candidateNodes: !root.micWatched ? [] : Pipewire.linkGroups.values
        .filter(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)
        .map(pwlg => pwlg.target)

    PwObjectTracker {
        objects: root.candidateNodes
    }

    function isPassiveMonitorStream(node) {
        const properties = node?.properties ?? {};
        const monitor = properties["stream.monitor"];
        const captureSink = properties["stream.capture.sink"];
        return monitor === true || monitor === "true" || captureSink === true || captureSink === "true";
    }

    readonly property list<var> micActiveNodes: root.candidateNodes.filter(node => node?.ready && !root.isPassiveMonitorStream(node))
    readonly property bool micActive: root.micActiveNodes.length > 0

    readonly property bool micIndicatorVisible: root.micWatched && root.micActive

    readonly property var videoCaptureCandidates: !root.videoWatched ? [] : Pipewire.linkGroups.values
        .filter(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
        .map(pwlg => ({ source: pwlg.source, target: pwlg.target }))

    readonly property var videoCaptureNodes: root.videoCaptureCandidates.reduce(
        (nodes, link) => nodes.concat([link.source, link.target]), [])

    PwObjectTracker {
        objects: root.videoCaptureNodes
    }

    function isCameraSource(source) {
        const properties = source?.properties ?? {};
        return properties["media.class"] === "Video/Source"
            && (properties["device.id"] !== undefined || properties["media.role"] === "Camera");
    }

    function isAppVideoStream(node) {
        return node?.properties?.["media.class"] === "Stream/Input/Video";
    }

    readonly property list<var> cameraCaptureLinks: root.videoCaptureCandidates.filter(link =>
        root.isCameraSource(link.source) && root.isAppVideoStream(link.target))
    readonly property list<var> screenCaptureLinks: root.videoCaptureCandidates.filter(link =>
        link.source?.properties?.["media.class"] === "Video/Source"
        && !root.isCameraSource(link.source) && root.isAppVideoStream(link.target))

    readonly property list<var> cameraCaptureNodes: root.cameraCaptureLinks.map(link => link.target)
    readonly property list<var> screenCaptureNodes: root.screenCaptureLinks.map(link => link.target)

    property bool scriptScreenRecording: false
    property int shellCaptureProcesses: 0
    property real shellCaptureHoldUntil: 0
    property bool shellCaptureHeld: false
    readonly property int shellCaptureGrace: 500
    readonly property bool shellCapturing: root.scriptScreenRecording || root.shellCaptureProcesses > 0 || root.shellCaptureHeld

    function holdShellCapture(ms: int) {
        const until = Date.now() + ms;
        if (until <= root.shellCaptureHoldUntil)
            return;
        root.shellCaptureHoldUntil = until;
        root.shellCaptureHeld = true;
        shellCaptureHoldTimer.interval = ms;
        shellCaptureHoldTimer.restart();
    }

    function beginShellCapture() {
        root.shellCaptureProcesses += 1;
    }

    function endShellCapture() {
        root.shellCaptureProcesses = Math.max(0, root.shellCaptureProcesses - 1);
        root.holdShellCapture(root.shellCaptureGrace);
    }

    Timer {
        id: shellCaptureHoldTimer
        repeat: false
        onTriggered: root.shellCaptureHeld = false
    }

    IpcHandler {
        target: "privacy"
        function screenRecordStarted() {
            root.scriptScreenRecording = true;
        }
        function screenRecordStopped() {
            root.scriptScreenRecording = false;
            root.holdShellCapture(root.shellCaptureGrace);
        }
    }

    property bool compositorCapture: false

    Timer {
        id: compositorCaptureTimeout
        interval: 500
        repeat: false
        onTriggered: root.compositorCapture = false
    }

    Connections {
        target: HyprlandData
        enabled: root.screenWatched
        function onScreencast(active, owner) {
            if (!active || owner === "window")
                return;
            if (!root.compositorCapture && root.shellCapturing)
                return;
            root.compositorCapture = true;
            compositorCaptureTimeout.restart();
        }
    }

    property var cameraDevices: ({})
    property string cameraDeviceApp: ""
    property bool cameraWatchPriming: false
    readonly property bool cameraDeviceCapture: Object.keys(root.cameraDevices).length > 0

    Process {
        id: cameraDeviceWatch
        running: root.cameraWatched && Config.options.bar.indicators.camera.watchDevices
        command: [`${Directories.scriptPath}/camera/camera-device-watch-venv.sh`]
        onStarted: root.cameraWatchPriming = true
        onRunningChanged: {
            if (running)
                return;
            root.cameraWatchPriming = false;
            root.cameraDeviceApp = "";
            root.cameraDevices = ({});
        }
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(" ");
                if (parts[0] === "READY") {
                    root.cameraWatchPriming = false;
                    return;
                }
                const device = parts[1] ?? "";
                if (device === "")
                    return;
                const devices = Object.assign({}, root.cameraDevices);
                if (parts[0] === "CAPTURE") {
                    const app = parts.slice(2).join(" ");
                    const takenOver = root.cameraActive && devices[device] !== app;
                    devices[device] = app;
                    root.cameraDeviceApp = app;
                    root.cameraDevices = devices;
                    if (takenOver && app !== "" && !root.cameraWatchPriming)
                        root.cameraCaptureStarted(null, app);
                } else if (parts[0] === "RELEASE") {
                    delete devices[device];
                    const apps = Object.values(devices);
                    root.cameraDeviceApp = apps.length > 0 ? apps[apps.length - 1] : "";
                    root.cameraDevices = devices;
                }
            }
        }
    }

    readonly property bool cameraActive: root.cameraCaptureLinks.length > 0 || root.cameraDeviceCapture
    readonly property bool screenCaptureActive: root.screenCaptureLinks.length > 0 || root.compositorCapture

    readonly property bool cameraIndicatorVisible: root.cameraWatched && root.cameraActive
    readonly property bool screenCaptureIndicatorVisible: root.screenWatched && root.screenCaptureActive

    signal cameraCaptureStarted(var node, string app)
    property bool previousCameraActive: false
    onCameraActiveChanged: {
        if (root.cameraActive && !root.previousCameraActive && !root.cameraWatchPriming)
            root.cameraCaptureStarted(root.cameraCaptureNodes[0], root.cameraDeviceApp);
        root.previousCameraActive = root.cameraActive;
    }

    signal screenCaptureStarted(var node)
    property bool previousScreenCaptureActive: false
    onScreenCaptureActiveChanged: {
        if (root.screenCaptureActive && !root.previousScreenCaptureActive) root.screenCaptureStarted(root.screenCaptureNodes[0]);
        root.previousScreenCaptureActive = root.screenCaptureActive;
    }

    signal micCaptureStarted(var node)
    property bool previousMicActive: false
    onMicActiveChanged: {
        if (root.micActive && !root.previousMicActive) root.micCaptureStarted(root.micActiveNodes[0]);
        root.previousMicActive = root.micActive;
    }
}

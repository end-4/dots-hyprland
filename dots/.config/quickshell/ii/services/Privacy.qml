pragma Singleton
pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 */
Singleton {
    id: root

    readonly property list<var> candidateNodes: Pipewire.linkGroups.values
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

    readonly property bool micIndicatorVisible: Config.options.bar.indicators.mic.showIndicator && root.micActive

    readonly property var videoCaptureCandidates: Pipewire.linkGroups.values
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

    property bool cameraDeviceCapture: false
    property string cameraDeviceApp: ""

    property bool scriptScreenRecording: false

    IpcHandler {
        target: "privacy"
        function screenRecordStarted() {
            root.scriptScreenRecording = true;
        }
        function screenRecordStopped() {
            root.scriptScreenRecording = false;
        }
    }

    Process {
        id: cameraDeviceWatch
        running: Config.options.bar.indicators.camera.watchDevices
        command: [`${Directories.scriptPath}/camera/camera-device-watch-venv.sh`]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(" ");
                if (parts[0] === "CAPTURE") {
                    const app = parts[2] ?? "";
                    if (app !== "" && app !== root.cameraDeviceApp)
                        root.cameraCaptureStarted(null, app);
                    root.cameraDeviceApp = app;
                    root.cameraDeviceCapture = true;
                } else if (parts[0] === "RELEASE") {
                    root.cameraDeviceApp = "";
                    root.cameraDeviceCapture = false;
                }
            }
        }
    }

    readonly property bool cameraActive: root.cameraCaptureLinks.length > 0 || root.cameraDeviceCapture
    readonly property bool screenCaptureActive: root.screenCaptureLinks.length > 0
        || HyprlandData.screencastActive

    readonly property bool cameraIndicatorVisible: Config.options.bar.indicators.camera.showIndicator && root.cameraActive
    readonly property bool screenCaptureIndicatorVisible: Config.options.bar.indicators.screen.showIndicator && root.screenCaptureActive

    signal cameraCaptureStarted(var node, string app)
    property bool previousCameraActive: false
    onCameraActiveChanged: {
        if (root.cameraActive && !root.previousCameraActive) root.cameraCaptureStarted(root.cameraCaptureNodes[0], root.cameraDeviceApp);
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

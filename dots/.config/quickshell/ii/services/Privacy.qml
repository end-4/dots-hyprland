pragma Singleton
pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Mic activity (who's currently recording).
 */
Singleton {
    id: root

    // Filtered by link source/target type rather than just "is there an input stream node"
    // (e.g. Audio.inputAppNodes): a node-only check can't tell a real mic capture apart from an
    // app (like cava) recording from a sink's monitor tap - only the link graph shows what the
    // stream is actually plugged into. A monitor tap's link source is the sink itself
    // (AudioSink), not a real capture device (AudioSource), so checking the link excludes it.
    readonly property list<var> candidateNodes: Pipewire.linkGroups.values
        .filter(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)
        .map(pwlg => pwlg.target)

    // Nodes reached only via a link group (not tracked elsewhere, e.g. by Audio.qml) don't have
    // their properties populated until explicitly tracked.
    PwObjectTracker {
        objects: root.candidateNodes
    }

    // Type-matching alone still isn't enough: apps that merely peek at the mic's level rather
    // than actually recording it - cava visualizing it, or pavucontrol's little peak meter next
    // to the input device - also link source=AudioSource/target=AudioInStream. PipeWire itself
    // tags these passive taps: stream.monitor is set on level-meter-only streams (confirmed via
    // pavucontrol's peak-detection nodes), and stream.capture.sink on streams capturing a sink's
    // monitor output instead of a real source (confirmed via cava). Excluding both filters out
    // "something is peeking at the audio" while keeping genuine recording.
    function isPassiveMonitorStream(node) {
        // A destroyed PwNode still reads back as ready for a turn after the stream goes away, and
        // its JS wrapper then becomes null. An unguarded read doesn't just fail: the exception
        // escapes the binding, and Qt keeps the binding frozen at its last good value forever, so
        // one dead node would leave micActive stuck (and the indicator lit) until a shell restart.
        const properties = node?.properties ?? {};
        const monitor = properties["stream.monitor"];
        const captureSink = properties["stream.capture.sink"];
        return monitor === true || monitor === "true" || captureSink === true || captureSink === "true";
    }

    // A node just added to candidateNodes hasn't necessarily been bound by the tracker yet, so
    // its properties (checked above) can still read back empty - wait for it to report ready
    // rather than counting it as "not proven to be a monitor stream yet" (which briefly flashed
    // the indicator on for genuine monitor-only taps before their properties caught up).
    readonly property list<var> micActiveNodes: root.candidateNodes.filter(node => node?.ready && !root.isPassiveMonitorStream(node))
    readonly property bool micActive: root.micActiveNodes.length > 0

    // The setting gates the persistent indicator as well as the one-off popup, and has to be read
    // as derived state rather than at the moment the capture starts: micActive is a binding over the
    // pipewire graph, so toggling the setting emits nothing on it and the icon would keep whatever
    // state it had when the switch flipped.
    readonly property bool micIndicatorVisible: Config.options.bar.indicators.mic.showIndicator && root.micActive

    // A camera and a screen share reach the graph the same way: an app's video stream linked to a
    // Video/Source node, and only the source tells them apart. A capture device carries a device.id
    // (and media.role = Camera), a screencast source is the portal's loop with no device behind it.
    //
    // Staged on purpose. Node types are readable without tracking, properties are not - so the
    // first stage filters by type only to get both ends tracked, and the second stage, which needs
    // media.class, can then actually see it. Filtering on media.class in the first stage would match
    // nothing, since an untracked node's properties are empty. PwNodeType is no help here: quickshell
    // has no VideoInStream/VideoOutStream, so both a camera app and a screen share arrive as
    // VideoSource -> Untracked. The media.class check on the source is also what keeps ordinary video
    // playback (Stream/Output/Video -> Video/Sink) out, even though its types are ambiguous.
    readonly property var videoCaptureCandidates: Pipewire.linkGroups.values
        .filter(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
        .map(pwlg => ({ source: pwlg.source, target: pwlg.target }))

    // Both ends need tracking for the second stage to see anything. QML's JS engine has no
    // flatMap, hence the reduce.
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

    // The app-side node, i.e. the one to name in a notification.
    readonly property list<var> cameraCaptureNodes: root.cameraCaptureLinks.map(link => link.target)
    readonly property list<var> screenCaptureNodes: root.screenCaptureLinks.map(link => link.target)

    readonly property bool cameraActive: root.cameraCaptureLinks.length > 0
    readonly property bool screenCaptureActive: root.screenCaptureLinks.length > 0

    readonly property bool cameraIndicatorVisible: Config.options.bar.indicators.camera.showIndicator && root.cameraActive
    readonly property bool screenCaptureIndicatorVisible: Config.options.bar.indicators.screen.showIndicator && root.screenCaptureActive

    // Same one-shot shape as the mic below: the popup needs the transition, not the level, and the
    // level alone emits nothing when the setting is flipped after the capture already started.
    signal cameraCaptureStarted(var node)
    property bool previousCameraActive: false
    onCameraActiveChanged: {
        if (root.cameraActive && !root.previousCameraActive) root.cameraCaptureStarted(root.cameraCaptureNodes[0]);
        root.previousCameraActive = root.cameraActive;
    }

    signal screenCaptureStarted(var node)
    property bool previousScreenCaptureActive: false
    onScreenCaptureActiveChanged: {
        if (root.screenCaptureActive && !root.previousScreenCaptureActive) root.screenCaptureStarted(root.screenCaptureNodes[0]);
        root.previousScreenCaptureActive = root.screenCaptureActive;
    }

    // Emitted once when mic capture goes from nobody-recording to somebody-recording (used to
    // show a one-off popup).
    signal micCaptureStarted(var node)
    property bool previousMicActive: false
    onMicActiveChanged: {
        if (root.micActive && !root.previousMicActive) root.micCaptureStarted(root.micActiveNodes[0]);
        root.previousMicActive = root.micActive;
    }
}

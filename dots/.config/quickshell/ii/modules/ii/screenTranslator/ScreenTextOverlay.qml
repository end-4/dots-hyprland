pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models.gCloud
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property double scaleFactor: 1
    property color overlayColor: "#BB000000"
    property color textColor: "white"
    required property string screenshotPath

    readonly property string wikiLink: "https://ii.clsty.link/en/ii-qs/02usage/#setting-it-up" // TODO: write a page for this
    readonly property string textColorDetectionScriptPath: Quickshell.shellPath("scripts/images/text-color-venv.sh")

    property bool loading: true
    property var visionParagraphs: []
    property list<string> translationKeys: []
    property var translation: ({})

    function translate(s: string): string {
        return translation[s] ?? s;
    }

    property bool error: false
    property string errorMessage: ""
    function showError() {
        error = true;
    }

    Component.onCompleted: {
        if (GoogleCloud.tokenReady && GoogleCloud.tokenError) {
            root.showError();
        }
        cloudVision.annotateImage(screenshotPath);
    }

    function reattemptAsNeeded() {
        if (root.visionParagraphs == [] && GoogleCloud.tokenReady && !GoogleCloud.tokenError) {
            root.error = false;
            cloudVision.annotateImage(root.screenshotPath);
        }
    }

    Connections {
        target: GoogleCloud
        function onTokenReadyChanged() {
            root.reattemptAsNeeded();
        }
    }

    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        opacity: root.loading ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
        }
        color: root.overlayColor

        Column {
            visible: !root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor
            MaterialLoadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 100 * root.scaleFactor
                scale: 1 + ((1 - loadingOverlay.opacity) * 0.5) * root.scaleFactor
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (cloudVision.state == GCloudApi.State.Preparing)
                        return Translation.tr("Uploading image");
                    else if (cloudVision.state == GCloudApi.State.Processing)
                        return Translation.tr("Reading image");
                    else if (cloudVision.state == GCloudApi.State.Error)
                        return Translation.tr("Error");
                    else if (cloudTrans.state == GCloudApi.State.Preparing)
                        return Translation.tr("Getting ready to translate");
                    else if (cloudTrans.state == GCloudApi.State.Processing)
                        return Translation.tr("Translating");
                    else
                        return " ";
                }
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                animateChange: true
                color: root.textColor
            }
        }

        Column {
            visible: root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor

            MaterialShapeWrappedMaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "exclamation"
                iconSize: 80 * root.scaleFactor
                padding: 6 * root.scaleFactor
                color: Appearance.colors.colError
                colSymbol: Appearance.colors.colOnError
                shape: MaterialShape.Shape.Sunny
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.windowWidth / 2, 800) * root.scaleFactor
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                text: `**${Translation.tr("Screen Translator")}**\n\n${root.errorMessage}\n\n__[${Translation.tr("See setup instructions on the wiki")}](${root.wikiLink})__`
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                color: root.textColor
                onLinkActivated: (link) => {
                    Qt.openUrlExternally(link)
                    GlobalStates.screenTranslatorOpen = false
                }

                PointingHandLinkHover {}
            }
        }
    }

    GCloudVisionResult {
        id: gcr
    }

    function handleError(msg) {
        if (msg?.length > 0) root.errorMessage = msg;
        else root.errorMessage = Translation.tr("Set your Google Cloud service account key");
        root.showError();
    }

    GCloudVision {
        id: cloudVision
        onError: (msg) => {
            root.handleError(msg);
        }
        onFinished: {
            gcr.initializeWithData(outputData);
            root.visionParagraphs = gcr.coherentParagraphs;
            // print(gcr.coherentParagraphs)
            root.translationKeys = gcr.coherentParagraphs.map(p => p.text);
            // print("TRANSLATION KEYS:", JSON.stringify(root.translationKeys));
            cloudTrans.translateStrings(root.translationKeys);
        }
    }

    GCloudTranslate {
        id: cloudTrans
        onError: (msg) => {
            root.handleError(msg);
        }
        onFinished: {
            var values = outputData.translations.map(translation => translation.translatedText);
            const keys = root.translationKeys;
            root.translation = ({});
            for (var i = 0; i < keys.length; i++) {
                Object.assign(root.translation, {
                    [keys[i]]: values[i]
                });
            }
            // print("TRANSLATION:", JSON.stringify(root.translation));
            root.loading = false;
        }
    }

    property real windowWidth: QsWindow.window.screen.width
    property real windowHeight: QsWindow.window.screen.height

    StyledImage {
        id: screenshotImage
        z: 1
        asynchronous: false
        width: root.windowWidth
        height: root.windowHeight
        sourceSize: Qt.size(root.windowWidth, root.windowHeight)
        source: Qt.resolvedUrl(root.screenshotPath)
        visible: false
    }

    Item {
        id: blurMaskItem
        z: 2
        width: root.windowWidth
        height: root.windowHeight
        layer.enabled: true
        visible: false
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: VisionBoundingBoxRect {
                readonly property string text: modelData.text
                readonly property string translatedText: root.translate(text)
                visible: translatedText != text
                scaleFactor: 1
            }
        }
    }

    // I no longer need these but they were a fucking pain in the ass to figure out so they're staying
    // GaussianBlur {
    //     id: blurredImage
    //     z: 3
    //     width: root.windowWidth
    //     height: root.windowHeight
    //     transformOrigin: Item.TopLeft
    //     scale: root.scaleFactor
    //     source: screenshotImage
    //     radius: 10
    //     samples: radius * 2 + 1
    //     visible: false
    // }
    // MultiEffect {
    //     id: blurredImage
    //     z: 3
    //     source: screenshotImage
    //     width: root.windowWidth
    //     height: root.windowHeight
    //     transformOrigin: Item.TopLeft
    //     scale: root.scaleFactor

    //     blurEnabled: true
    //     blur: 1
    //     blurMax: 64
    //     visible: false
    // }

    MaskMultiEffect {
        z: 4
        implicitWidth: parent.width
        implicitHeight: parent.height
        width: parent.width
        height: parent.height

        // Mask
        source: screenshotImage
        maskSource: blurMaskItem

        // Blur
        blurEnabled: true
        blur: 1
        blurMax: 50
        blurMultiplier: root.scaleFactor
        autoPaddingEnabled: false
    }

    Item {
        id: textItems
        z: 999
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            // An entry looks like this:
            delegate: TextItem {}
        }
    }

    component VisionBoundingBoxRect: Rectangle {
        required property var modelData
        property real scaleFactor: root.scaleFactor
        property list<var> boundingVertices: modelData.boundingBox.vertices
        property real unscaledX: boundingVertices[0].x
        property real unscaledY: boundingVertices[0].y
        property real unscaledWidth: boundingVertices[1].x - boundingVertices[0].x
        property real unscaledHeight: boundingVertices[3].y - boundingVertices[0].y
        
        // Calculate rotation based on first two vertices (top-left to top-right)
        property real dx: boundingVertices[1].x - boundingVertices[0].x
        property real dy: boundingVertices[1].y - boundingVertices[0].y
        transformOrigin: Item.TopLeft
        rotation: {
            // Note rotation in qml is degrees clockwise
            var angle = Math.atan2(dy, dx) * 180 / Math.PI;
            return angle;
        }
        
        x: unscaledX * scaleFactor
        y: unscaledY * scaleFactor
        width: unscaledWidth * scaleFactor
        height: unscaledHeight * scaleFactor
        radius: 4
    }

    component TextItem: VisionBoundingBoxRect {
        id: ti
        // {"boundingPoly": {"vertices": [{"x": 536,"y": 236},{"x": 583,"y": 236},{"x": 583,"y": 262},{"x": 536,"y": 262}]},"description": "宮坂"}
        readonly property string text: modelData.text
        readonly property string translatedText: root.translate(text)
        visible: translatedText != text

        color: ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.4)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Loader {
            active: ti.visible
            sourceComponent: MultiTurnProcess {
                Component.onCompleted: {
                    runSequence([ //
                        [ //
                            "bash", "-c", //
                            `magick ${StringUtils.shellSingleQuoteEscape(root.screenshotPath)} +repage -crop ${StringUtils.shellSingleQuoteEscape(ti.unscaledWidth)}x${StringUtils.shellSingleQuoteEscape(ti.unscaledHeight)}+${StringUtils.shellSingleQuoteEscape(ti.unscaledX)}+${StringUtils.shellSingleQuoteEscape(ti.unscaledY)} png:- | ${root.textColorDetectionScriptPath}`
                        ],
                        (out => {
                            var colorData = JSON.parse(out);
                            ti.color = ColorUtils.transparentize(colorData.background, 0.4);
                            tiText.color = colorData.text;
                        })
                    ]);
                }
            }
        }

        SqueezedAnnotationStyledText {
            id: tiText
            width: parent.width
            height: parent.height
            text: ti.translatedText
            scaleFactor: root.scaleFactor

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}

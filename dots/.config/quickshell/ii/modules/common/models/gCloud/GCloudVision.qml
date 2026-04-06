pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.common.utils
import qs.services
import qs.modules.common
import ".."

GCloudApi {
    id: root

    readonly property string imageBase64FilePath: `${Directories.screenshotTemp}/vision_base64.txt`
    readonly property string payloadFilePath: `${Directories.screenshotTemp}/vision_payload.json`
    property string uploadEndpoint: "https://uguu.se/upload"

    property bool tokenReady: GoogleCloud.tokenReady
    property bool onlineImageReady: false
    readonly property bool preparationReady: tokenReady && onlineImageReady

    function annotateImage(imageUri: string) {
        resetState();
        root.state = GCloudApi.State.Preparing;
        root.onlineImageReady = false
        GoogleCloud.load();

        var seq = []; // command sequence

        const niceFilePath = StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(imageUri))
        seq = [ //
            ["bash", "-c", `mkdir -p '${Directories.screenshotTemp}'; base64 '${niceFilePath}' -w 0 > '${imageBase64FilePath}'`], //
            (out) => { //
                root.onlineImageReady = true; //
            }
        ]

        // Execute the base64 conversion & load the token
        prepMultiproc.runSequence(seq);
    }

    onPreparationReadyChanged: {
        if (!preparationReady) return;
        if (GoogleCloud.tokenError || GoogleCloud.keyError) {
            root.state = GCloudApi.State.Error;
            root.error(Translation.tr("Set your Google Cloud service account key"));
            return;
        }
        root.state = GCloudApi.State.Processing;
        var seq = []; // command sequence

        // Construct the JSON payload using jq to read from the base64 file
        seq.push([
            "bash", "-c",
            `jq -n --rawfile content '${imageBase64FilePath}' \
'{"requests": [{"image": {"content": $content}, "features": [{"type": "DOCUMENT_TEXT_DETECTION"}]}]}' \
> '${payloadFilePath}'`
        ]);

        seq.push([
            "bash", "-c",
            `curl -s -X POST \
-H "Authorization: Bearer ${GoogleCloud.token}" \
-H "x-goog-user-project: ${GoogleCloud.projectId}" \
-H "Content-Type: application/json" \
https://vision.googleapis.com/v1/images:annotate \
-d @'${payloadFilePath}'`
        ]);

        seq.push((out) => {
            root.handleApiOutput(out);
        });

        lookMultiproc.runSequence(seq);
    }

    MultiTurnProcess {
        id: prepMultiproc
    }

    MultiTurnProcess {
        id: lookMultiproc
    }
}

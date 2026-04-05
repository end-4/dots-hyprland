pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.functions
import qs.modules.common.utils
import qs.services
import ".."

GCloudApi {
    id: root

    property list<string> pendingStrings
    property bool setupReady: false
    readonly property bool preparationReady: GoogleCloud.tokenReady && setupReady

    function translateStrings(strings: list<string>) {
        GoogleCloud.load();
        root.setupReady = false;
        root.pendingStrings = strings;
        root.state = GCloudApi.State.Preparing;
        root.setupReady = true;
    }

    onPreparationReadyChanged: {
        if (!preparationReady) return;
        root.state = GCloudApi.State.Processing;

        const targetLang = Translation.languageCode;
        const payload = {
            "targetLanguageCode": targetLang,
            "contents": root.pendingStrings,
            "mimeType": "text/plain"
        };

        // print("PENDING STRINGS:", root.pendingStrings)

        var seq = [];
        seq.push([ //
            "bash", "-c", //
            `curl -sL -X POST \
-H "Authorization: Bearer ${GoogleCloud.token}" \
-H "x-goog-user-project: ${GoogleCloud.projectId}" \
-H "Content-Type: application/json" \
-d '${StringUtils.shellSingleQuoteEscape(JSON.stringify(payload))}' \
"https://translation.googleapis.com/v3/projects/${GoogleCloud.projectId}:translateText"`
        ]);

        seq.push(((out) => {
            root.handleApiOutput(out);
        }));

        multiproc.runSequence(seq);
    }

    MultiTurnProcess {
        id: multiproc
    }
}

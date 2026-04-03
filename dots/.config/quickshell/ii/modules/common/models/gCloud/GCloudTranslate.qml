pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.functions
import qs.modules.common.utils
import qs.services
import ".."

NestableObject {
    id: root

    enum State {
        Done, Preparing, Processing
    }

    signal finished()
    property var outputData
    property var state: GCloudTranslate.State.Done

    property list<string> pendingStrings
    property bool setupReady: false
    readonly property bool preparationReady: GoogleCloud.tokenReady && setupReady

    function translateStrings(strings: list<string>) {
        GoogleCloud.load();
        root.setupReady = false;
        root.pendingStrings = strings;
        root.state = GCloudTranslate.State.Preparing;
        root.setupReady = true;
    }

    onPreparationReadyChanged: {
        if (!preparationReady) return;
        root.state = GCloudTranslate.State.Processing;

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
            // print(out)
            root.outputData = JSON.parse(out);
            root.pendingStrings = [];
            root.finished();
            root.state = GCloudTranslate.State.Done;
        }));

        multiproc.runSequence(seq);
    }

    MultiTurnProcess {
        id: multiproc
    }
}

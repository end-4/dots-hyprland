pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.common.utils
import qs.services
import qs.modules.common
import ".."

NestableObject {
    id: root

    enum State {
        Done, Preparing, Processing, Error
    }

    signal finished()
    signal error(message: string)
    property int errorCode
    property string errorMessage: ""
    property var outputData
    property var state: GCloudApi.State.Done

    function resetState() {
        root.state = GCloudApi.State.Done;
        root.errorMessage = "";
        root.outputData = undefined;
    }

    function handleApiOutput(out: string): bool {
        try {
            root.outputData = JSON.parse(out);
            if (outputData.error) {
                print("API error: " + JSON.stringify(outputData.error, null, 2))
                root.state = GCloudApi.State.Error;
                root.errorCode = outputData.error.code;
                root.errorMessage = outputData.error.message;
                root.error(outputData.error.message);
                return false;
            }
            root.finished();
            root.state = GCloudApi.State.Done;
            return true
        } catch (e) {
            print("Failed to parse API response: " + e + "\n" + out)
            root.state = GCloudApi.State.Error;
            root.errorMessage = "Failed to parse API response";
            root.error(root.errorMessage);
            return false;
        }
    }
}

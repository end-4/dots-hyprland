import QtQuick;

/**
 * Represents a message in an AI conversation. (Kind of) follows the OpenAI API message structure.
 */
QtObject {
    property string role
    property string content
    property string rawContent
    property string fileMimeType
    property string fileUri
    property string localFilePath
    property string model
    property bool thinking: true
    property bool done: false
    property var annotations: []
    property var annotationSources: []
    property list<string> searchQueries: []
    property string cliSessionId
    property string functionName
    property var functionCall
    property string functionResponse
    property bool functionPending: false
    // Ordinal (among the message's ```command fences) of the one awaiting approval
    property int pendingCommandIndex: -1
    property bool visibleToUser: true
}

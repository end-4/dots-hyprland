import "root:/modules/common"
import QtQuick;

QtObject {
    property string role
    property string content
    property string model
    property bool thinking: true
    property bool done: false
    property var annotations: []
    property var annotationSources: []
}

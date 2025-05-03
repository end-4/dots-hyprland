import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

QtObject {
    property string provider
    property list<var> tags
    property var page
    property list<var> images
    property string message
}

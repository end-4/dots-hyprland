import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property int sidebarRightOpenCount: 0
    property bool overviewOpen: false
}
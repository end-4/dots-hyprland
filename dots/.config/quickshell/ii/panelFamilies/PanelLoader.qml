import QtQuick
import Quickshell

import qs.modules.common

LazyLoader {
    property bool extraCondition: true
    // Async so panels don't block each other (and the bar from showing up) on startup
    activeAsync: Config.ready && extraCondition
}

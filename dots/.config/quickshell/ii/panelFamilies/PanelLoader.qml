import QtQuick
import Quickshell

import qs.modules.common

LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

StyledImage {
    id: avatar
    Layout.alignment: Qt.AlignTop
    sourceSize: Qt.size(32, 32)
    source: Directories.userAvatarPathAccountsService
    fallbacks: [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Circle {
            diameter: avatar.height
        }
    }
}

pragma Singleton

import QtQuick

QtObject {
    id: root

    property var offsetByScreen: ({})
    property var bottomOffsetByScreen: ({})

    function setOffset(screenName, offset) {
        const copy = Object.assign({}, offsetByScreen)
        copy[screenName] = offset
        offsetByScreen = copy
    }

    function offset(screenName) {
        return offsetByScreen[screenName] ?? 0
    }

    function setBottomOffset(screenName, offset) {
        const copy = Object.assign({}, bottomOffsetByScreen)
        copy[screenName] = offset
        bottomOffsetByScreen = copy
    }

    function bottomOffset(screenName) {
        return bottomOffsetByScreen[screenName] ?? 0
    }
}

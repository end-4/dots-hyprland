pragma Singleton

import QtQuick

QtObject {
    id: root

    property var offsetByScreen: ({})

    function setOffset(screenName, offset) {
        const copy = Object.assign({}, offsetByScreen)
        copy[screenName] = offset
        offsetByScreen = copy
    }

    function offset(screenName) {
        return offsetByScreen[screenName] ?? 0
    }
}

pragma Singleton
import QtQml

QtObject {
    property int setManyCalls: 0
    property int resetManyCalls: 0
    property var lastSetMany: null
    property var lastResetMany: null

    function clearCalls() {
        setManyCalls = 0
        resetManyCalls = 0
        lastSetMany = null
        lastResetMany = null
    }

    function setMany(values) {
        setManyCalls += 1
        lastSetMany = values
    }

    function resetMany(keys) {
        resetManyCalls += 1
        lastResetMany = keys
    }
}

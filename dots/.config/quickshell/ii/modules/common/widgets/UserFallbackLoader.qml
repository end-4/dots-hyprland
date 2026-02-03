import QtQuick
import qs.modules.common as C

FallbackLoader {
    id: root

    required property string componentName
    property string context // Path for the builtin component

    readonly property string componentNameWithExt: componentName.endsWith(".qml") ? componentName : `${componentName}.qml`

    source: `${C.Directories.userComponents}/${componentNameWithExt}`
    fallbacks: [
        ...(context ? [ `${context}/${componentNameWithExt}` ] : []),
        componentNameWithExt
    ]
}

pragma Singleton
// hyprland-settings/qml/Theme.qml

import QtQuick

Item {
    id: themeRoot
    
    property color background: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.background : "#161217")
    property color surface: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.surface : "#231E23")
    property color surfaceHigh: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.surfaceHigh : "#2D282E")
    property color text: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.text : "#EAE0E7")
    property color subtext: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.subtext : "#988E97")
    property color primary: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.primary : "#E5B6F2")
    property color outline: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.outline : "#4C444D")
    property color error: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.error : "#FFB4AB")
    property color surfaceContainerLow: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.surfaceContainerLow : "#181818")
    property color surfaceContainer: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.surfaceContainer : "#222")
    property color surfaceContainerHigh: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.surfaceContainerHigh : "#333")

    // ИЗМЕНЕНИЕ: Новые цвета для навигации
    property color secondaryContainer: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.secondaryContainer : "#403742")
    property color onSecondaryContainer: (ThemeManager && ThemeManager.theme ? ThemeManager.theme.onSecondaryContainer : "#E8DEF8")

    readonly property int radius: 12
    readonly property QtObject mainFont: QtObject {
        readonly property string family: "Noto Sans"
        readonly property int pixelSize: 16
    }
    readonly property QtObject titleFont: QtObject {
        readonly property string family: "Noto Sans"
        readonly property int pixelSize: 22
        readonly property int weight: Font.Bold
    }
    readonly property QtObject monoFont: QtObject {
        readonly property string family: "JetBrains Mono"
        readonly property int pixelSize: 16
    }
}
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Singleton {
    id: toggleStyles

    property QtObject small
    property QtObject normal
    property QtObject large
    readonly property var toggleTypeMap: ({
        0: "small",
        1: "normal",
        2: "large"
    })
    readonly property string rounding: Config.options.quickToggles.androidStyle?.rounding || "normal"
    readonly property bool androidStyle: Config.options.quickToggles.androidStyle.enable
    readonly property bool enableBorder: Config.options.quickToggles.androidStyle.enableBorder

    readonly property real buttonRadiusPressed: Appearance.rounding[smallerRoundingMap[toggleStyles.rounding]]
    readonly property real buttonRadius: Appearance.rounding[toggleStyles.rounding]
    readonly property bool transparency : Appearance.contentTransparency
    readonly property bool dark : Appearance.m3colors.darkmode

    // It looked ugly in transparent mode so i decided to do some experiments
    readonly property color borderColorHover: transparency ? (dark ? Appearance.colors.colPrimary : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.5)) : dark ? Appearance.colors.colPrimary : ColorUtils.colorWithLightness(Appearance.colors.colPrimary, 0.4)
    readonly property color borderColor: transparency ? (dark ? ColorUtils.transparentize(Appearance.colors.colLayer3, transparency -0.2) : Appearance.colors.colLayer0Hover) : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 , 0.15)
    readonly property real borderWidth: androidStyle && toggleStyles.enableBorder ? 1.5 : 0  // 1 look pixelated

    readonly property color colBackground: transparency ? (dark ? ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.1): Appearance.colors.colLayer1 ): (dark ? Appearance.colors.colLayer1 :Appearance.colors.colLayer2)
    readonly property color colBackgroundHover: transparency ? ( dark ? ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.2): Appearance.colors.colLayer0) :( dark ? Appearance.colors.colLayer1Hover:Appearance.colors.colLayer2Hover)
    readonly property color colBackgroundActive: transparency ? ( dark ? ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.3) : Appearance.colors.colLayer0Active) :( dark ? Appearance.colors.colLayer1Active:Appearance.colors.colLayer2Active)

    readonly property color colBackgroundToggled: Appearance.colors.colPrimary ?? "#65558F"
    readonly property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover ?? "#77699C"
    readonly property color colBackgroundToggledActive: Appearance.colors.colPrimaryActive ?? "#D6CEE2"


    small: QtObject {
        // used to calculate padding
        readonly property int scalar: 0
        readonly property int baseWidth: 40
        readonly property int baseHeight: 40
        readonly property int iconSize: androidStyle ? 22 : 20
        // parity with original toggle
        readonly property color colBackground: ColorUtils.transparentize(Appearance?.colors.colLayer1Hover, 1) || "transparent"
        readonly property real buttonRadius: androidStyle ? toggleStyles.buttonRadius : Math.min(baseHeight, baseWidth) / 2
        readonly property real buttonRadiusPressed: androidStyle ? toggleStyles.buttonRadiusPressed : Appearance.rounding.small
        readonly property real buttonRadiusToggled: androidStyle ? toggleStyles.buttonRadiusPressed : Appearance.rounding.normal
    }

    normal: QtObject {
        readonly property int scalar: 0
        readonly property int baseWidth: 65
        readonly property int baseHeight: 65
        readonly property int iconSize: 24
        readonly property color colBackground: toggleStyles.colBackground
        readonly property real buttonRadiusPressed: toggleStyles.buttonRadiusPressed
        readonly property real buttonRadius: toggleStyles.buttonRadius

     }

    large: QtObject {
        readonly property int scalar: 1
        readonly property int baseWidth: 196
        readonly property int baseHeight: 65
        readonly property int iconSize: 24
        readonly property color colBackground:toggleStyles.colBackground
        readonly property real buttonRadiusPressed: toggleStyles.buttonRadiusPressed
        readonly property real buttonRadius: toggleStyles.buttonRadius

     }

    readonly property var smallerRoundingMap: ({
            "full": "full",
            "verylarge": "large",
            "large": "normal",
            "normal": "normal",
            "small": "small"
        })
}

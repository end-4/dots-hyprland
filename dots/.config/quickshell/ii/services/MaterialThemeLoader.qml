pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    // Only these JSON keys map to existing m3colors properties (paletteKeyColor etc. are excluded)
    readonly property var _validM3Keys: [
        "m3background", "m3onBackground", "m3surface", "m3surfaceDim", "m3surfaceBright",
        "m3surfaceContainerLowest", "m3surfaceContainerLow", "m3surfaceContainer",
        "m3surfaceContainerHigh", "m3surfaceContainerHighest", "m3onSurface", "m3surfaceVariant",
        "m3onSurfaceVariant", "m3inverseSurface", "m3inverseOnSurface", "m3outline", "m3outlineVariant",
        "m3shadow", "m3scrim", "m3surfaceTint", "m3primary", "m3onPrimary", "m3primaryContainer",
        "m3onPrimaryContainer", "m3inversePrimary", "m3secondary", "m3onSecondary", "m3secondaryContainer",
        "m3onSecondaryContainer", "m3tertiary", "m3onTertiary", "m3tertiaryContainer", "m3onTertiaryContainer",
        "m3error", "m3onError", "m3errorContainer", "m3onErrorContainer", "m3primaryFixed",
        "m3primaryFixedDim", "m3onPrimaryFixed", "m3onPrimaryFixedVariant", "m3secondaryFixed",
        "m3secondaryFixedDim", "m3onSecondaryFixed", "m3onSecondaryFixedVariant", "m3tertiaryFixed",
        "m3tertiaryFixedDim", "m3onTertiaryFixed", "m3onTertiaryFixedVariant", "m3success",
        "m3onSuccess", "m3successContainer", "m3onSuccessContainer",
        "term0","term1","term2","term3","term4","term5","term6","term7","term8",
        "term9","term10","term11","term12","term13","term14","term15"
    ]

    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (!json.hasOwnProperty(key)) continue
            // Convert snake_case to CamelCase (e.g. surfaceContainerLow -> m3surfaceContainerLow)
            const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
            const m3Key = (key.match(/^term\d+$/) ? key : `m3${camelCaseKey}`)
            if (root._validM3Keys.indexOf(m3Key) !== -1) {
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        // Infer darkmode from background lightness
        try {
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
        } catch (e) {
            Appearance.m3colors.darkmode = true
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["bash", "-c", `"${FileUtils.trimFileProtocol(Directories.wallpaperSwitchScriptPath)}" --noswitch 2>/dev/null`])
                retryLoadWhenReady.restart()
            } else {
                root.resetFilePathNextTime()
            }
        }
    }

    Timer {
        id: retryLoadWhenReady
        interval: 2000
        repeat: true
        running: false
        onTriggered: {
            themeFileView.reload()
            if (themeFileView.loaded)
                retryLoadWhenReady.stop()
        }
    }
}

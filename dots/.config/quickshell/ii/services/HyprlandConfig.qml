pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Hyprland
 */
Singleton {
    id: root
    
    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/hyprconfigurator.py")
    readonly property string shellOverridesPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/main.conf`)

    function set(key: string, value: var) {
        Quickshell.execDetached(["bash", "-c", //
            `${root.configuratorScriptPath} --file ${root.shellOverridesPath} --set "${key}" "${value}"` //
        ])
    }
    
    function setMany(entries: var) {
        let args = ""
        for (let key in entries) {
            args += `--set "${key}" "${entries[key]}" `
        }
        Quickshell.execDetached(["bash", "-c", //
            `${root.configuratorScriptPath} --file ${root.shellOverridesPath} ${args}` //
        ])
    }
    
    function reset(key: string) {
        Quickshell.execDetached(["bash", "-c", //
            `${root.configuratorScriptPath} --file ${root.shellOverridesPath} --reset "${key}"` //
        ])
    }
    
    function resetMany(keys: var) {
        let args = ""
        for (let i = 0; i < keys.length; i++) {
            args += `--reset "${keys[i]}" `
        }
        Quickshell.execDetached(["bash", "-c", //
            `${root.configuratorScriptPath} --file ${root.shellOverridesPath} ${args}` //
        ])
    }
}

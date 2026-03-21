pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.launcher.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.launcher.pinnedApps = Config.options.launcher.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.launcher.pinnedApps = Config.options.launcher.pinnedApps.concat([appId])
        }
    }

    function moveToFront(appId) {
        if (!root.isPinned(appId)) return;
        const pinnedApps = Config.options.launcher.pinnedApps;
        Config.options.launcher.pinnedApps = [appId].concat(pinnedApps.filter(id => id !== appId));
    }

    function moveLeft(appId) {
        const pinnedApps = Config.options.launcher.pinnedApps;
        const index = pinnedApps.indexOf(appId);
        if (index === -1 || index === 0) return;
        Config.options.launcher.pinnedApps = pinnedApps.slice(0, index - 1).concat([appId]).concat(pinnedApps[index - 1]).concat(pinnedApps.slice(index + 1));
    }

    function moveRight(appId) {
        const pinnedApps = Config.options.launcher.pinnedApps;
        const index = pinnedApps.indexOf(appId);
        if (index === -1 || index === pinnedApps.length - 1) return;
        Config.options.launcher.pinnedApps = pinnedApps.slice(0, index).concat(pinnedApps[index + 1]).concat([appId]).concat(pinnedApps.slice(index + 2));
    }

    function uninstallApp(appId) {
        if (!appId) return;
        // Run in terminal so user sees output and can enter pkexec password.
        // Order: Flatpak -> pacman (official + AUR). Use pacman -R (remove package only).
        const script = `
            echo "Uninstalling: ${appId}"
            echo ""
            if flatpak list --app --columns=application 2>/dev/null | grep -qx "${appId}"; then
                echo "Found as Flatpak. Running: flatpak uninstall -y ${appId}"
                flatpak uninstall -y "${appId}"
            else
                # Find .desktop file (may be in subdirs)
                path=$(find /usr/share/applications "$HOME/.local/share/applications" -name "${appId}.desktop" 2>/dev/null | head -1)
                if [ -n "$path" ]; then
                    # pacman -Qo outputs: "/path is owned by pkgname version"
                    owner=$(pacman -Qo "$path" 2>/dev/null | awk '{print $5}')
                    if [ -n "$owner" ]; then
                        echo "Found package: $owner. Running: pkexec pacman -Rn $owner"
                        pkexec pacman -Rn "$owner"
                    else
                        echo "Could not find package to uninstall."
                        notify-send "Uninstall" "Could not find package for: ${appId}" -a Shell 2>/dev/null || true
                    fi
                else
                    echo "Could not find package to uninstall."
                    notify-send "Uninstall" "Could not find package for: ${appId}" -a Shell 2>/dev/null || true
                fi
            fi
            echo ""
            read -p "Press Enter to close..."
        `;
        const term = (Config?.options?.apps?.terminal ?? "kitty -1").split(/\s+/);
        const termExec = term[0];
        const termArgs = term.slice(1).concat(["-e", "bash", "-c", script]);
        Quickshell.execDetached([termExec].concat(termArgs));
    }
}

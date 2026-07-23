pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function reorderPinned(from, to) {
        var arr = Config.options.dock.pinnedApps.slice();
        var item = arr.splice(from, 1)[0];
        arr.splice(to, 0, item);
        Config.options.dock.pinnedApps = arr;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    // Keyed by appId so unchanged apps keep the same TaskbarAppEntry identity
    // across recomputation. Recreating every entry from scratch on each
    // rebuild (e.g. on every window open/close) made ScriptModel see the
    // whole dock list as removed+re-added, since it can only diff QObject
    // values by pointer identity, not by their objectProp.
    property var _entryCache: new Map()

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        // Mutate the cache object in place (never reassign root._entryCache)
        // so this binding doesn't depend on its own writes and loop.
        var cache = root._entryCache;
        var values = [];

        for (const [key, value] of map) {
            var entry = cache.get(key);
            if (entry) {
                entry.toplevels = value.toplevels;
                entry.pinned = value.pinned;
            } else {
                entry = appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned });
                cache.set(key, entry);
            }
            values.push(entry);
        }

        for (const oldKey of cache.keys()) {
            if (!map.has(oldKey)) {
                cache.get(oldKey).destroy();
                cache.delete(oldKey);
            }
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}

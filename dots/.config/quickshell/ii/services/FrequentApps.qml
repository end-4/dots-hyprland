pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common

Singleton {
    id: root

    readonly property bool tracking: Config.options.search.showFrequentApps && Persistent.ready
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property string activeAppId: activeWindow?.appId ?? ""
    property Toplevel lastWindow: null
    property string lastAppId: ""

    readonly property var entries: {
        const installed = new Map(DesktopEntries.applications.values.map(entry => [entry.id, entry]));
        return Persistent.states.frequentApps
            .filter(record => installed.has(record.id))
            .sort((a, b) => b.count - a.count || b.lastUsed - a.lastUsed)
            .slice(0, Math.max(1, Math.min(20, Config.options.search.frequentAppsCount)))
            .map(record => installed.get(record.id));
    }

    function recordActiveApp() {
        if (!tracking || !activeWindow?.appId)
            return;

        const entry = DesktopEntries.heuristicLookup(activeWindow.appId);
        if (!entry || entry.noDisplay)
            return;

        const alreadyRecorded = lastWindow !== null && lastAppId === entry.id;
        lastWindow = activeWindow;
        lastAppId = entry.id;
        if (alreadyRecorded)
            return;

        const records = Persistent.states.frequentApps.slice();
        const index = records.findIndex(record => record.id === entry.id);
        const record = {id: entry.id, count: (records[index]?.count ?? 0) + 1, lastUsed: Date.now()};
        if (index === -1)
            records.push(record);
        else
            records[index] = record;
        Persistent.states.frequentApps = records;
    }

    onTrackingChanged: recordActiveApp()
    onActiveWindowChanged: recordActiveApp()
    onActiveAppIdChanged: recordActiveApp()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.recordActiveApp();
        }
    }
}

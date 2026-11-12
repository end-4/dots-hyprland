pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.ii.island

// Pending pacman and AUR updates as an idle glance item. The repo count comes from a
// synced copy of the pacman db (a checkupdates equivalent without pacman-contrib), so
// the real db is never touched and no root is needed (pacman 7 needs --disable-sandbox under fakeroot). One shell run prints "repo aur".
Item {
    id: root

    readonly property string glanceId: "updates"
    Component.onDestruction: IslandState.clearGlance(root.glanceId) // switched off in Settings
    // Shell line run by bash. Prints "<repo count> <aur count>" and nothing else.
    // With arg "sync" it refreshes the copied sync dbs from the mirrors first; follow-up
    // checks skip that and just re-count against the installed packages.
    readonly property string script: "db=\"${XDG_RUNTIME_DIR:-/tmp}/island-checkup-db\"; mkdir -p \"$db\"; ln -sfn /var/lib/pacman/local \"$db/local\"; [ \"$1\" = sync ] && fakeroot -- pacman -Sy --disable-sandbox --dbpath \"$db\" --logfile /dev/null >/dev/null 2>&1; repo=$(pacman -Qu --dbpath \"$db\" 2>/dev/null | grep -vc '\\[ignored\\]'); aur=0; for h in yay paru; do if command -v $h >/dev/null 2>&1; then aur=$($h -Qua 2>/dev/null | wc -l); break; fi; done; echo \"${repo:-0} $aur\""

    // Parses "repo aur" and updates the glance. A failed run (no numbers) keeps the last state.
    function onCounts(output) {
        const parts = output.trim().split(/\s+/).map(s => parseInt(s));
        if (parts.length < 2 || isNaN(parts[0]) || isNaN(parts[1]))
            return;
        const repo = parts[0];
        const aur = parts[1];
        if (repo + aur > 0) {
            IslandState.setGlance(root.glanceId, {
                icon: "system_update_alt",
                text: root.updatesText(repo, aur),
                priority: 60,
                // end-4's own update command (Config.options.apps.update), like the waffle updates button.
                command: ["bash", "-c", Config.options.apps.update]
            });
            // Re-check 2 min later so finished updates show up sooner.
            retry.restart();
        } else {
            IslandState.clearGlance(root.glanceId);
        }
    }

    // "1 update", "3 updates (2 AUR)", "2 AUR updates".
    function updatesText(repo: int, aur: int): string {
        // Whole phrases, so each language can word (and pluralise) them its own way.
        const total = repo + aur;
        if (repo === 0)
            return (aur === 1 ? Translation.tr("%1 AUR update") : Translation.tr("%1 AUR updates")).arg(aur);
        if (aur > 0)
            return Translation.tr("%1 updates (%2 AUR)").arg(total).arg(aur);
        return (total === 1 ? Translation.tr("%1 update") : Translation.tr("%1 updates")).arg(total);
    }

    // Never overlaps: a request while a run is in progress is dropped.
    function check(sync: bool) {
        if (scan.running)
            return;
        scan.command = ["bash", "-c", root.script, "island", sync ? "sync" : "nosync"];
        scan.running = true;
    }

    Process {
        id: scan
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: root.onCounts(text)
        }
    }

    // First check 45 s after load, so the shell is settled.
    Timer {
        interval: 45000
        running: true
        onTriggered: root.check(true)
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.check(true)
    }

    // Follow-up after a run that found updates. One-shot; restarted by each such run.
    Timer {
        id: retry
        interval: 120000
        onTriggered: root.check(false) // no mirror sync, just re-count
    }
}

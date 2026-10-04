pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Model aliases offered by the local Claude Code CLI.
 * Fetched through /models
 */
Singleton {
    id: root

    property var aliases: []

    // The CLI runs locally but sends chats to Anthropic, so the local-only policy excludes it
    readonly property bool allowed: Config.options.policies.ai !== 2

    function forget() {
        cache.setText("[]");
        root.aliases = [];
    }

    // Aliases come back instantly from the last run's cache; the CLI query refreshes them
    // in the background (a cold `claude` start takes a few seconds)
    FileView {
        id: cache
        path: Directories.claudeModelListCachePath
        watchChanges: false
        onLoadedChanged: {
            if (!loaded || !root.allowed) return;
            try {
                root.aliases = JSON.parse(cache.text());
            } catch (e) {
                console.log("Could not load cached Claude CLI models:", e);
            }
        }
    }

    Process {
        id: checkAuth
        running: root.allowed
        // `command -v` first, so a missing CLI is 127 and not whatever claude itself exited with
        command: ["bash", "-c", "command -v claude >/dev/null || exit 127; claude auth status --json"]
        stdout: StdioCollector { id: authOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 127) { // Not installed
                root.forget();
                return;
            }
            if (exitCode !== 0) return;
            let loggedIn;
            try {
                loggedIn = JSON.parse(authOutput.text).loggedIn;
            } catch (e) {
                console.log("Could not read Claude CLI auth status:", e);
                return;
            }
            if (loggedIn) queryModels.running = true;
            else root.forget();
        }
    }

    Process {
        id: queryModels
        // Started by checkAuth, so a logged-out user never pays for a cold `claude` start
        command: ["bash", "-c", "claude -p '/model'"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Replies like "... Available: sonnet, opus, fable, default, or a full model ID."
                const found = (text.match(/Available: ([^\n]+)/)?.[1] ?? "").split(",")
                    .map(alias => alias.trim().replace(/\.$/, ""))
                    // Drops the trailing "or a full model ID" and meta aliases
                    .filter(alias => alias.length > 0 && !alias.includes(" ")
                        && !["default", "best", "opusplan"].includes(alias));
                if (found.length === 0) {
                    console.log("Could not read the Claude CLI model list");
                    return;
                }
                root.aliases = found;
                cache.setText(JSON.stringify(found));
            }
        }
    }
}

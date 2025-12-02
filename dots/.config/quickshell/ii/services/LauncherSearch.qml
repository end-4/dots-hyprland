pragma Singleton

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""
    property var searchActions: [
        {
            action: "accentcolor",
            execute: args => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", ...(args != '' ? [`${args}`] : [])]);
            }
        },
        {
            action: "dark",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
            }
        },
        {
            action: "konachanwallpaper",
            execute: () => {
                Quickshell.execDetached([Quickshell.shellPath("scripts/colors/random/random_konachan_wall.sh")]);
            }
        },
        {
            action: "light",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
            }
        },
        {
            action: "superpaste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    // Invalid if doesn't start with numbers
                    Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "wallpaper",
            execute: () => {
                GlobalStates.wallpaperSelectorOpen = true;
            }
        },
        {
            action: "wipeclipboard",
            execute: () => {
                Cliphist.wipe();
            }
        },
    ]

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords))
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined) return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    property list<var> results: {
        // Search results are handled here
        ////////////////// Skip? //////////////////
        if (root.query == "")
            return [];

        ///////////// Special cases ///////////////
        if (root.query.startsWith(Config.options.search.prefix.clipboard)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            return Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                return {
                    key: type,
                    cliphistRawString: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    clickActionName: "",
                    type: type,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [
                        {
                            name: "Copy",
                            materialIcon: "content_copy",
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        },
                        {
                            name: "Delete",
                            materialIcon: "delete",
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        }
                    ],
                    blurImage: shouldBlurImage,
                    blurImageText: Translation.tr("Work safety")
                };
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return {
                    key: emoji,
                    cliphistRawString: entry,
                    bigText: emoji,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    clickActionName: "",
                    type: "Emoji",
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                };
            }).filter(Boolean);
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = {
            key: `Math result: ${root.mathResult}`,
            name: root.mathResult,
            clickActionName: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: "monospace",
            materialSymbol: 'calculate',
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        };
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            entry.clickActionName = Translation.tr("Launch");
            entry.type = Translation.tr("App");
            entry.key = entry.execute;
            return entry;
        });
        const commandResultObject = {
            key: `cmd ${root.query}`,
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            clickActionName: Translation.tr("Run"),
            type: Translation.tr("Run command"),
            fontType: "monospace",
            materialSymbol: 'terminal',
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", searchingText.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        };
        const webSearchResultObject = {
            key: `website ${root.query}`,
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            clickActionName: Translation.tr("Search"),
            type: Translation.tr("Search the web"),
            materialSymbol: 'travel_explore',
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        };
        const launcherActionObjects = root.searchActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return {
                    key: `Action ${actionString}`,
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    clickActionName: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    materialSymbol: 'settings_suggest',
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                };
            }
            return null;
        }).filter(Boolean);

        //////// Prioritized by prefix /////////
        let result = [];
        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);
        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        //////////////// Apps //////////////////
        result = result.concat(appResultObjects);

        ////////// Launcher actions ////////////
        result = result.concat(launcherActionObjects);

        /// Math result, command, web search ///
        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }

        return result;
    }
}

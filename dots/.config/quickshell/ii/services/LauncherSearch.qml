pragma Singleton

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""

    function normalizeSearchTerm(value) {
        const normalized = (value || "").trim().toLowerCase().replace(/\s+/g, " ");
        if (!normalized)
            return "";
        return normalized.split(" ").map(token => normalizeToken(token)).join(" ");
    }

    function getSmartSearchRecords() {
        return Persistent.states.search?.appClickStats || [];
    }

    function normalizeToken(token) {
        if (!token)
            return "";

        if (token.endsWith("ies") && token.length > 3)
            return token.slice(0, -3) + "y";
        if (token.endsWith("es") && token.length > 3)
            return token.slice(0, -2);
        if (token.endsWith("s") && token.length > 3 && !token.endsWith("ss"))
            return token.slice(0, -1);
        return token;
    }

    function tokenSet(text) {
        return Array.from(new Set((text || "").split(" ").filter(Boolean)));
    }

    function jaccardSimilarity(setAList, setBList) {
        if (!setAList.length || !setBList.length)
            return 0;

        let overlap = 0;
        for (const a of setAList) {
            if (setBList.includes(a))
                overlap++;
        }
        const union = Array.from(new Set(setAList.concat(setBList))).length;
        return union > 0 ? overlap / union : 0;
    }

    function querySimilarity(a, b) {
        if (!a || !b)
            return 0;
        if (a === b)
            return 1;
        return jaccardSimilarity(tokenSet(a), tokenSet(b));
    }

    function signatureSimilarity(currentIds, historicalSignature) {
        if (!currentIds.length || !historicalSignature)
            return 0;
        const historicalIds = historicalSignature.split("|").filter(Boolean);
        return jaccardSimilarity(currentIds, historicalIds);
    }

    function resultSignature(appIds) {
        if (!appIds || appIds.length === 0)
            return "";
        return appIds.slice().sort().join("|");
    }

    function exactAppMatchScore(entry, normalizedSearch) {
        if (!normalizedSearch)
            return 0;

        const name = (entry.name || "").trim().toLowerCase();
        const genericName = (entry.genericName || "").trim().toLowerCase();
        if (name === normalizedSearch)
            return 3;
        if (genericName === normalizedSearch)
            return 2;
        if (name.startsWith(normalizedSearch))
            return 1;
        return 0;
    }

    readonly property int smartSearchHeavyThreshold: 8

    function exactQueryClickCount(entryId, normalizedSearch, records) {
        if (!entryId || !normalizedSearch || !records)
            return 0;
        let total = 0;
        for (const rec of records) {
            if (rec.appId === entryId && rec.query === normalizedSearch)
                total += Number(rec.count) || 0;
        }
        return total;
    }

    function smartSearchScore(entry, normalizedSearch, candidateIds, signature, records) {
        if (!Config.options.search.smartSearch)
            return 0;

        const entryId = entry?.id || "";
        if (!entryId)
            return 0;

        let score = 0;
        for (const rec of records) {
            if (rec.appId !== entryId)
                continue;
            const clicks = Number(rec.count) || 0;
            if (clicks <= 0)
                continue;
            if (normalizedSearch && rec.query && rec.query.startsWith(normalizedSearch) && rec.query !== normalizedSearch) {
                // Short prefix intent, e.g. "disc" should inherit from frequent "discord" selections.
                score += clicks * 95;
            }
            if (normalizedSearch && rec.query === normalizedSearch) {
                score += clicks * 100;
            } else {
                const qSimilarity = querySimilarity(normalizedSearch, rec.query || "");
                if (qSimilarity >= 0.5)
                    score += clicks * qSimilarity * 70;
            }
            if (signature && rec.signature === signature) {
                score += clicks * 80;
            } else {
                const sSimilarity = signatureSimilarity(candidateIds, rec.signature || "");
                if (sSimilarity >= 0.5)
                    score += clicks * sSimilarity * 75;
            }
        }
        return score;
    }

    function getInjectedPrefixEntries(normalizedSearch, existingEntries, records) {
        if (!Config.options.search.smartSearch)
            return [];
        if (!normalizedSearch || normalizedSearch.length < 2)
            return [];

        const existingIds = new Set((existingEntries || []).map(entry => entry.id || "").filter(Boolean));
        const aggregated = ({});
        for (const rec of records) {
            const recQuery = rec.query || "";
            const appId = rec.appId || "";
            const clicks = Number(rec.count) || 0;
            if (!appId || clicks <= 0 || existingIds.has(appId))
                continue;
            if (!recQuery.startsWith(normalizedSearch) || recQuery === normalizedSearch)
                continue;

            if (!aggregated[appId]) {
                aggregated[appId] = {
                    appId: appId,
                    score: 0,
                    lastUsed: 0
                };
            }
            aggregated[appId].score += clicks;
            aggregated[appId].lastUsed = Math.max(aggregated[appId].lastUsed, Number(rec.lastUsed) || 0);
        }

        const topIds = Object.values(aggregated)
            .sort((a, b) => {
                if (a.score !== b.score)
                    return b.score - a.score;
                return b.lastUsed - a.lastUsed;
            })
            .slice(0, 3)
            .map(item => item.appId);

        const byId = ({});
        for (const app of AppSearch.list) {
            byId[app.id] = app;
        }
        return topIds.map(id => byId[id]).filter(Boolean);
    }

    function rankAppEntries(entries, rawSearchTerm) {
        if (!entries)
            return [];

        const normalizedSearch = normalizeSearchTerm(rawSearchTerm);
        const records = getSmartSearchRecords();
        let candidateEntries = entries.slice();
        const injectedEntries = getInjectedPrefixEntries(normalizedSearch, candidateEntries, records);
        candidateEntries = candidateEntries.concat(injectedEntries);
        if (candidateEntries.length <= 1)
            return candidateEntries;

        const candidateIds = candidateEntries.map(entry => entry.id || "").filter(Boolean);
        const signature = resultSignature(candidateIds);

        const threshold = root.smartSearchHeavyThreshold;
        return candidateEntries
            .map((entry, index) => {
                const exactScore = exactAppMatchScore(entry, normalizedSearch);
                const smartScore = smartSearchScore(entry, normalizedSearch, candidateIds, signature, records);
                const exactQueryClicks = exactQueryClickCount(entry.id || "", normalizedSearch, records);
                const heavyForExactQuery = exactQueryClicks >= threshold;
                const combinedScore = (heavyForExactQuery ? 5000 : 0) + exactScore * 1000 + smartScore;
                return {
                    entry: entry,
                    index: index,
                    exactScore: exactScore,
                    smartScore: smartScore,
                    combinedScore: combinedScore
                };
            })
            .sort((a, b) => {
                if (a.combinedScore !== b.combinedScore)
                    return b.combinedScore - a.combinedScore;
                return a.index - b.index;
            })
            .map(item => item.entry);
    }

    function registerAppClick(rawSearchTerm, candidateIds, selectedId) {
        if (!Config.options.search.smartSearch || !selectedId)
            return;

        const normalizedSearch = normalizeSearchTerm(rawSearchTerm);
        const signature = resultSignature(candidateIds || []);
        const records = getSmartSearchRecords().slice();
        const now = Date.now();
        let matched = false;

        for (let i = 0; i < records.length; i++) {
            const rec = records[i];
            if (rec.appId === selectedId && rec.query === normalizedSearch && rec.signature === signature) {
                records[i] = {
                    appId: rec.appId,
                    query: rec.query,
                    signature: rec.signature,
                    count: (Number(rec.count) || 0) + 1,
                    lastUsed: now
                };
                matched = true;
                break;
            }
        }
        if (!matched) {
            records.push({
                appId: selectedId,
                query: normalizedSearch,
                signature: signature,
                count: 1,
                lastUsed: now
            });
        }

        if (records.length > 500) {
            records.sort((a, b) => (Number(b.lastUsed) || 0) - (Number(a.lastUsed) || 0));
            records.length = 500;
        }
        Persistent.states.search.appClickStats = records;
    }

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.allApps, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }

    // https://specifications.freedesktop.org/menu/latest/category-registry.html
    property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
    property list<string> appCategories: DesktopEntries.applications.values.reduce((acc, entry) => {
        for (const category of entry.categories) {
            if (!acc.includes(category) && mainRegisteredCategories.includes(category)) {
                acc.push(category);
            }
        }
        return acc;
    }, []).sort()

    // Load user action scripts from ~/.config/illogical-impulse/actions/
    // Uses FolderListModel to auto-reload when scripts are added/removed
    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, ""); // strip extension
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

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

    // Combined built-in and user actions
    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
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

        ///////////// All apps (no overview, same size as search) ///////////////
        if (root.query.startsWith(Config.options.search.prefix.allApps)) {
            const cleaned = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.allApps);
            const appEntries = rankAppEntries(cleaned === "" ? AppSearch.list : AppSearch.fuzzyQuery(cleaned), cleaned);
            const candidateIds = appEntries.map(entry => entry.id || "").filter(Boolean);
            return appEntries.map(entry => resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    root.registerAppClick(cleaned, candidateIds, entry.id);
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            }));
        }

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
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const appSearchTerm = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app);
        const appEntries = rankAppEntries(AppSearch.fuzzyQuery(appSearchTerm), appSearchTerm);
        const appCandidateIds = appEntries.map(entry => entry.id || "").filter(Boolean);
        const appResultObjects = appEntries.map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    root.registerAppClick(appSearchTerm, appCandidateIds, entry.id);
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        // Probably needs more proper escaping, but this will do for now
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
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

    property list<var> allAppResults: (function() {
        const list = AppSearch.list;
        const arr = [];
        for (let i = 0; i < list.length; i++) {
            const entry = list[i];
            arr.push(resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            }));
        }
        return arr;
    })()

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}

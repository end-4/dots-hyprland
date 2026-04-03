pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions as CF
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services.ai

/**
 * CLI-first chat service for shell-native AI providers.
 * Visible providers are intentionally curated:
 * - Codex CLI
 * - Gemini CLI
 * - Claude Code
 * - Kimi Code CLI
 * - Kimi API
 */
Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property Component aiModelComponent: AiModel {}
    property Component claudeCliStrategy: ClaudeCliStrategy {}
    property Component codexCliStrategy: CodexCliStrategy {}
    property Component geminiCliStrategy: GeminiCliStrategy {}
    property Component kimiApiStrategy: KimiApiStrategy {}
    property Component kimiCliStrategy: KimiCliStrategy {}
    readonly property string interfaceRole: "interface"
    readonly property string apiKeyEnvVarName: "API_KEY"

    signal responseFinished()

    property string systemPrompt: {
        let prompt = Config.options?.ai?.systemPrompt ?? "";
        for (let key in root.promptSubstitutions) {
            // prompt = prompt.replaceAll(key, root.promptSubstitutions[key]);
            // QML/JS doesn't support replaceAll, so use split/join
            prompt = prompt.split(key).join(root.promptSubstitutions[key]);
        }
        return prompt;
    }
    // property var messages: []
    property var messageIDs: []
    property var messageByID: ({})
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}
    readonly property var apiKeysLoaded: KeyringStorage.loaded
    readonly property bool currentModelHasApiKey: {
        const model = models[currentModelId];
        if (!model || !model.requires_key) return true;
        if (!apiKeysLoaded) return false;
        const key = apiKeys[model.key_id];
        return (key?.length > 0);
    }
    property var postResponseHook
    property real temperature: Persistent.states?.ai?.temperature ?? 0.5
    property QtObject tokenCount: QtObject {
        property int input: -1
        property int output: -1
        property int total: -1
    }

    function idForMessage(message) {
        // Generate a unique ID using timestamp and random value
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    property list<var> defaultPrompts: []
    property list<var> userPrompts: []
    property list<var> promptFiles: [...defaultPrompts, ...userPrompts]
    property list<var> savedChats: []

    property var promptSubstitutions: {
        "{DISTRO}": SystemInfo.distroName,
        "{DATETIME}": `${DateTime.time}, ${DateTime.collapsedCalendarFormat}`,
        "{WINDOWCLASS}": ToplevelManager.activeToplevel?.appId ?? "Unknown",
        "{DE}": `${SystemInfo.desktopEnvironment} (${SystemInfo.windowingSystem})` 
    }

    property string currentTool: Config?.options.ai.tool ?? "none"
    property var tools: {
        "codex_cli": {
            "functions": [],
            "search": [],
            "none": [],
        },
        "claude_cli": {
            "functions": [],
            "search": [],
            "none": [],
        },
        "gemini_cli": {
            "functions": [],
            "search": [],
            "none": [],
        },
        "kimi_api": {
            "functions": [],
            "search": [],
            "none": [],
        },
        "kimi_cli": {
            "functions": [],
            "search": [],
            "none": [],
        }
    }
    property list<var> availableTools: Object.keys(root.tools[models[currentModelId]?.api_format] ?? { "none": [] })
    property var toolDescriptions: {
        "none": Translation.tr("CLI-first mode. Shared skills/actions will be added on top of providers instead of API function calling.")
    }

    property var models: Config.options.policies.ai === 2 ? {} : {
        "codex": aiModelComponent.createObject(this, {
            "name": "Codex CLI",
            "icon": "openai-symbolic",
            "description": Translation.tr("Local coding agent via Codex CLI | Uses your ChatGPT login"),
            "homepage": "https://developers.openai.com/codex/",
            "endpoint": "",
            "model": "codex",
            "requires_key": false,
            "api_format": "codex_cli",
            "extraParams": {
                "cwd": CF.FileUtils.trimFileProtocol(Directories.home),
                "approval_mode": "suggest",
            },
        }),
        "claude-cli": aiModelComponent.createObject(this, {
            "name": "Claude Code",
            "icon": "openai-symbolic",
            "description": Translation.tr("Local coding agent via Claude Code | Read-only by default"),
            "homepage": "https://code.claude.com/docs/en/cli-usage",
            "endpoint": "",
            "model": "sonnet",
            "requires_key": false,
            "api_format": "claude_cli",
            "extraParams": {
                "cwd": CF.FileUtils.trimFileProtocol(Directories.home),
                "binary_path": `${CF.FileUtils.trimFileProtocol(Directories.home)}/.npm-global/bin/claude`,
                "permission_mode": "plan",
            },
        }),
        "gemini-cli": aiModelComponent.createObject(this, {
            "name": "Gemini CLI",
            "icon": "google-gemini-symbolic",
            "description": Translation.tr("Local coding/research agent via Gemini CLI | Uses your Google login"),
            "homepage": "https://github.com/google-gemini/gemini-cli",
            "endpoint": "",
            "model": "gemini-2.5-pro",
            "requires_key": false,
            "api_format": "gemini_cli",
            "extraParams": {
                "cwd": CF.FileUtils.trimFileProtocol(Directories.home),
                "binary_path": `${CF.FileUtils.trimFileProtocol(Directories.home)}/.npm-global/bin/gemini`,
            },
        }),
        "kimi-cli": aiModelComponent.createObject(this, {
            "name": "Kimi Code CLI",
            "icon": "mistral-symbolic",
            "description": Translation.tr("Local agent via Kimi CLI | Uses your Moonshot login | Print mode may auto-approve tools"),
            "homepage": "https://moonshotai.github.io/kimi-cli/en/reference/kimi-command.html",
            "endpoint": "",
            "model": "kimi-k2",
            "requires_key": false,
            "api_format": "kimi_cli",
            "extraParams": {
                "cwd": CF.FileUtils.trimFileProtocol(Directories.home),
                "binary_path": `${CF.FileUtils.trimFileProtocol(Directories.home)}/.local/bin/kimi`,
            },
        }),
        "kimi-api": aiModelComponent.createObject(this, {
            "name": "Kimi API",
            "icon": "mistral-symbolic",
            "description": Translation.tr("Network fallback via Kimi API | Best for broad research when you want an explicit API path"),
            "homepage": "https://platform.moonshot.ai",
            "endpoint": "https://api.moonshot.ai/v1/chat/completions",
            "model": "kimi-k2.5",
            "requires_key": true,
            "key_id": "moonshot",
            "key_get_link": "https://platform.moonshot.ai/console/api-keys",
            "key_get_description": Translation.tr("**Instructions**: Create a Moonshot API key and paste it with `/key YOUR_API_KEY` when Kimi API is selected."),
            "api_format": "kimi_api",
        }),
    }
    property var modelList: Object.keys(root.models)
    property string defaultModelId: "codex"
    property var currentModelId: (Persistent.states?.ai?.model && (Persistent.states.ai.model in root.models))
        ? Persistent.states.ai.model
        : ((defaultModelId in root.models) ? defaultModelId : modelList[0])

    property var apiStrategies: {
        "claude_cli": claudeCliStrategy.createObject(this),
        "gemini_cli": geminiCliStrategy.createObject(this),
        "kimi_api": kimiApiStrategy.createObject(this),
        "kimi_cli": kimiCliStrategy.createObject(this),
        "codex_cli": codexCliStrategy.createObject(this),
    }
    property ApiStrategy currentApiStrategy: apiStrategies[models[currentModelId]?.api_format || "codex_cli"]

    property string requestScriptFilePath: "/tmp/quickshell/ai/request.sh"
    property string pendingFilePath: ""

    Component.onCompleted: {
        setModel(currentModelId, false, false); // Do necessary setup for model
    }

    Process {
        id: getDefaultPrompts
        running: true
        command: ["ls", "-1", Directories.defaultAiPrompts]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                root.defaultPrompts = text.split("\n")
                    .filter(fileName => fileName.endsWith(".md") || fileName.endsWith(".txt"))
                    .map(fileName => `${Directories.defaultAiPrompts}/${fileName}`)
            }
        }
    }

    Process {
        id: getUserPrompts
        running: true
        command: ["ls", "-1", Directories.userAiPrompts]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                root.userPrompts = text.split("\n")
                    .filter(fileName => fileName.endsWith(".md") || fileName.endsWith(".txt"))
                    .map(fileName => `${Directories.userAiPrompts}/${fileName}`)
            }
        }
    }

    Process {
        id: getSavedChats
        running: true
        command: ["ls", "-1", Directories.aiChats]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                root.savedChats = text.split("\n")
                    .filter(fileName => fileName.endsWith(".json"))
                    .map(fileName => `${Directories.aiChats}/${fileName}`)
            }
        }
    }

    FileView {
        id: promptLoader
        watchChanges: false;
        onLoadedChanged: {
            if (!promptLoader.loaded) return;
            Config.options.ai.systemPrompt = promptLoader.text();
            root.addMessage(Translation.tr("Loaded the following system prompt\n\n---\n\n%1").arg(Config.options.ai.systemPrompt), root.interfaceRole);
        }
    }

    function printPrompt() {
        root.addMessage(Translation.tr("The current system prompt is\n\n---\n\n%1").arg(Config.options.ai.systemPrompt), root.interfaceRole);
    }

    function currentWorkspacePath() {
        return models[currentModelId]?.extraParams?.cwd ?? CF.FileUtils.trimFileProtocol(Directories.home);
    }

    function printWorkspacePath() {
        root.addMessage(Translation.tr("Current workspace:\n\n```txt\n%1\n```").arg(root.currentWorkspacePath()), root.interfaceRole);
    }

    function setWorkspacePath(path) {
        const model = models[currentModelId];
        if (!model || model.requires_key) {
            root.addMessage(Translation.tr("Workspace context is only used by local CLI providers."), root.interfaceRole);
            return;
        }

        const trimmedPath = CF.FileUtils.trimFileProtocol(path).trim();
        if (trimmedPath.length === 0) {
            root.addMessage(Translation.tr("Usage: /cwd /path/to/project"), root.interfaceRole);
            return;
        }

        model.extraParams = Object.assign({}, model.extraParams, {
            "cwd": trimmedPath,
        });
        root.addMessage(Translation.tr("Workspace set to:\n\n```txt\n%1\n```").arg(trimmedPath), root.interfaceRole);
    }

    function loadPrompt(filePath) {
        promptLoader.path = "" // Unload
        promptLoader.path = filePath; // Load
        promptLoader.reload();
    }

    function addMessage(message, role) {
        if (message.length === 0) return;
        const aiMessage = aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
            "rawContent": message,
            "thinking": false,
            "done": true,
        });
        const id = idForMessage(aiMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = aiMessage;
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length) return;
        const id = root.messageIDs[index];
        root.messageIDs.splice(index, 1);
        root.messageIDs = [...root.messageIDs];
        delete root.messageByID[id];
    }

    function addApiKeyAdvice(model) {
        root.addMessage(
            Translation.tr('To set an API key, pass it with the %4 command\n\nTo view the key, pass "get" with the command<br/>\n\n### For %1:\n\n**Link**: %2\n\n%3')
                .arg(model.name).arg(model.key_get_link).arg(model.key_get_description ?? Translation.tr("<i>No further instruction provided</i>")).arg("/key"), 
            Ai.interfaceRole
        );
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId, feedback = true, setPersistentState = true) {
        if (!modelId) modelId = ""
        modelId = modelId.toLowerCase()
        if (modelList.indexOf(modelId) !== -1) {
            const model = models[modelId]
            // See if policy prevents online models
            const isLocalModel = !model.requires_key && (!model.endpoint || model.endpoint.length === 0 || model.endpoint.includes("localhost"));
            if (Config.options.policies.ai === 2 && !isLocalModel) {
                root.addMessage(
                    Translation.tr("Online models disallowed\n\nControlled by `policies.ai` config option"),
                    root.interfaceRole
                );
                return;
            }
            if (setPersistentState) Persistent.states.ai.model = modelId;
            const providerTools = root.tools[model.api_format] ?? { "none": [] };
            if (!(root.currentTool in providerTools))
                Config.options.ai.tool = "none";
            if (feedback) root.addMessage(Translation.tr("Model set to %1").arg(model.name), root.interfaceRole);
            if (model.requires_key) {
                // If key not there show advice
                if (root.apiKeysLoaded && (!root.apiKeys[model.key_id] || root.apiKeys[model.key_id].length === 0)) {
                    root.addApiKeyAdvice(model)
                }
            }
        } else {
            if (feedback) root.addMessage(Translation.tr("Invalid model. Supported: \n```\n") + modelList.join("\n```\n```\n"), Ai.interfaceRole) + "\n```"
        }
    }

    function setTool(tool) {
        if (!root.tools[models[currentModelId]?.api_format] || !(tool in root.tools[models[currentModelId]?.api_format])) {
            root.addMessage(Translation.tr("Invalid tool. Supported tools:\n- %1").arg(root.availableTools.join("\n- ")), root.interfaceRole);
            return false;
        }
        Config.options.ai.tool = tool;
        return true;
    }
    
    function getTemperature() {
        return root.temperature;
    }

    function setTemperature(value) {
        if (value == NaN || value < 0 || value > 2) {
            root.addMessage(Translation.tr("Temperature must be between 0 and 2"), Ai.interfaceRole);
            return;
        }
        Persistent.states.ai.temperature = value;
        root.temperature = value;
        root.addMessage(Translation.tr("Temperature set to %1").arg(value), Ai.interfaceRole);
    }

    function setApiKey(key) {
        const model = models[currentModelId];
        if (!model.requires_key) {
            root.addMessage(Translation.tr("API keys are only used by Kimi API. Switch to `kimi-api` first if you want to configure one."), Ai.interfaceRole);
            return;
        }
        if (!key || key.length === 0) {
            const model = models[currentModelId];
            root.addApiKeyAdvice(model)
            return;
        }
        KeyringStorage.setNestedField(["apiKeys", model.key_id], key.trim());
        root.addMessage(Translation.tr("API key set for %1").arg(model.name), Ai.interfaceRole);
    }

    function printApiKey() {
        const model = models[currentModelId];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage(Translation.tr("API key:\n\n```txt\n%1\n```").arg(key), Ai.interfaceRole);
            } else {
                root.addMessage(Translation.tr("No API key set for %1").arg(model.name), Ai.interfaceRole);
            }
        } else {
            root.addMessage(Translation.tr("API keys are only used by Kimi API."), Ai.interfaceRole);
        }
    }

    function printTemperature() {
        root.addMessage(Translation.tr("Temperature: %1").arg(root.temperature), Ai.interfaceRole);
    }

    function clearMessages() {
        root.messageIDs = [];
        root.messageByID = ({});
        root.tokenCount.input = -1;
        root.tokenCount.output = -1;
        root.tokenCount.total = -1;
    }

    FileView {
        id: requesterScriptFile
    }

    Process {
        id: requester
        property list<string> baseCommand: ["bash"]
        property AiMessageData message
        property ApiStrategy currentStrategy
        workingDirectory: CF.FileUtils.trimFileProtocol(Directories.home)

        function markDone() {
            requester.message.done = true;
            if (root.postResponseHook) {
                root.postResponseHook();
                root.postResponseHook = null; // Reset hook after use
            }
            root.saveChat("lastSession")
            root.responseFinished()
        }

        function makeRequest() {
            const model = models[currentModelId];

            // Fetch API keys if needed
            if (model?.requires_key && !KeyringStorage.loaded) KeyringStorage.fetchKeyringData();
            
            requester.currentStrategy = root.currentApiStrategy;
            requester.currentStrategy.reset(); // Reset strategy state
            requester.workingDirectory = CF.FileUtils.trimFileProtocol(Directories.home);

            /* Put API key in environment variable */
            if (model.requires_key) requester.environment[`${root.apiKeyEnvVarName}`] = root.apiKeys ? (root.apiKeys[model.key_id] ?? "") : ""

            /* Build endpoint, request data */
            const endpoint = root.currentApiStrategy.buildEndpoint(model);
            const messageArray = root.messageIDs.map(id => root.messageByID[id]);
            const filteredMessageArray = messageArray.filter(message => message.role !== Ai.interfaceRole);
            const data = root.currentApiStrategy.buildRequestData(
                model,
                filteredMessageArray,
                root.systemPrompt,
                root.temperature,
                root.tools[model.api_format]?.[root.currentTool] ?? [],
                root.pendingFilePath
            );
            // console.log("[Ai] Request data: ", JSON.stringify(data, null, 2));

            let requestHeaders = {
                "Content-Type": "application/json",
            }
            
            /* Create local message object */
            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "rawContent": "",
                "thinking": true,
                "done": false,
            });
            const id = idForMessage(requester.message);
            root.messageIDs = [...root.messageIDs, id];
            root.messageByID[id] = requester.message;

            if (model.api_format === "codex_cli") {
                requester.workingDirectory = data.cwd && data.cwd.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.cwd)
                    : CF.FileUtils.trimFileProtocol(Directories.home);
                requester.command = [
                    "codex",
                    "exec",
                    "--json",
                    "--skip-git-repo-check",
                    "-C",
                    requester.workingDirectory,
                    data.prompt
                ];
                requester.running = true;
                return;
            }

            if (model.api_format === "gemini_cli") {
                requester.workingDirectory = data.cwd && data.cwd.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.cwd)
                    : CF.FileUtils.trimFileProtocol(Directories.home);
                requester.environment["II_GEMINI_PROMPT"] = data.prompt;
                requester.environment["II_GEMINI_MODEL"] = data.model && data.model.length > 0 ? data.model : "gemini-2.5-pro";
                requester.environment["II_GEMINI_BIN"] = data.binaryPath && data.binaryPath.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.binaryPath)
                    : "gemini";
                requester.command = [
                    "bash",
                    "-lc",
                    "GEMINI_BIN=\"$II_GEMINI_BIN\"; " +
                    "if [ ! -x \"$GEMINI_BIN\" ]; then GEMINI_BIN=\"$(command -v gemini 2>/dev/null || true)\"; fi; " +
                    "if [ -z \"$GEMINI_BIN\" ]; then " +
                        "printf '{\"type\":\"result\",\"text\":\"**Error**: Gemini CLI is not installed. Install it with `npm install -g @google/gemini-cli` and run `gemini` once to sign in.\",\"done\":true}\\n'; " +
                        "exit 0; " +
                    "fi; " +
                    "exec \"$GEMINI_BIN\" -p \"$II_GEMINI_PROMPT\" --output-format stream-json -m \"$II_GEMINI_MODEL\"",
                ];
                if (root.pendingFilePath.length > 0)
                    root.pendingFilePath = "";
                requester.running = true;
                return;
            }

            if (model.api_format === "claude_cli") {
                requester.workingDirectory = data.cwd && data.cwd.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.cwd)
                    : CF.FileUtils.trimFileProtocol(Directories.home);
                requester.environment["II_CLAUDE_PROMPT"] = data.prompt;
                requester.environment["II_CLAUDE_MODEL"] = data.model && data.model.length > 0 ? data.model : "sonnet";
                requester.environment["II_CLAUDE_BIN"] = data.binaryPath && data.binaryPath.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.binaryPath)
                    : "claude";
                requester.environment["II_CLAUDE_PERMISSION_MODE"] = data.permissionMode && data.permissionMode.length > 0 ? data.permissionMode : "plan";
                requester.command = [
                    "bash",
                    "-lc",
                    "CLAUDE_BIN=\"$II_CLAUDE_BIN\"; " +
                    "if [ ! -x \"$CLAUDE_BIN\" ]; then CLAUDE_BIN=\"$(command -v claude 2>/dev/null || true)\"; fi; " +
                    "if [ -z \"$CLAUDE_BIN\" ]; then " +
                        "printf '{\"type\":\"result\",\"result\":\"**Error**: Claude Code is not installed. Install it with `npm install -g @anthropic-ai/claude-code` and run `claude auth login`.\",\"done\":true}\\n'; " +
                        "exit 0; " +
                    "fi; " +
                    "exec \"$CLAUDE_BIN\" -p \"$II_CLAUDE_PROMPT\" --model \"$II_CLAUDE_MODEL\" --output-format stream-json --permission-mode \"$II_CLAUDE_PERMISSION_MODE\"",
                ];
                requester.running = true;
                return;
            }

            if (model.api_format === "kimi_cli") {
                requester.workingDirectory = data.cwd && data.cwd.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.cwd)
                    : CF.FileUtils.trimFileProtocol(Directories.home);
                requester.environment["II_KIMI_PROMPT"] = data.prompt;
                requester.environment["II_KIMI_MODEL"] = data.model && data.model.length > 0 ? data.model : "kimi-k2";
                requester.environment["II_KIMI_BIN"] = data.binaryPath && data.binaryPath.length > 0
                    ? CF.FileUtils.trimFileProtocol(data.binaryPath)
                    : "kimi";
                requester.command = [
                    "bash",
                    "-lc",
                    "KIMI_BIN=\"$II_KIMI_BIN\"; " +
                    "if [ ! -x \"$KIMI_BIN\" ]; then KIMI_BIN=\"$(command -v kimi 2>/dev/null || true)\"; fi; " +
                    "if [ -z \"$KIMI_BIN\" ]; then " +
                        "printf '{\"type\":\"result\",\"text\":\"**Error**: Kimi CLI is not installed. Install it first, then run `kimi login`.\",\"done\":true}\\n'; " +
                        "exit 0; " +
                    "fi; " +
                    "exec \"$KIMI_BIN\" --print --output-format stream-json --final-message-only -m \"$II_KIMI_MODEL\" -w \"$PWD\" -p \"$II_KIMI_PROMPT\"",
                ];
                requester.running = true;
                return;
            }

            /* Build header string for curl */ 
            let headerString = Object.entries(requestHeaders)
                .filter(([k, v]) => v && v.length > 0)
                .map(([k, v]) => `-H '${k}: ${v}'`)
                .join(' ');

            // console.log("Request headers: ", JSON.stringify(requestHeaders));
            // console.log("Header string: ", headerString);

            /* Get authorization header from strategy */
            const authHeader = requester.currentStrategy.buildAuthorizationHeader(root.apiKeyEnvVarName);
            
            /* Script shebang */
            const scriptShebang = "#!/usr/bin/env bash\n";

            /* Create extra setup when there's an attached file */
            let scriptFileSetupContent = ""
            if (root.pendingFilePath && root.pendingFilePath.length > 0) {
                requester.message.localFilePath = root.pendingFilePath;
                scriptFileSetupContent = requester.currentStrategy.buildScriptFileSetup(root.pendingFilePath);
                root.pendingFilePath = ""
            }

            /* Create command string */
            let scriptRequestContent = ""
            scriptRequestContent += `curl --no-buffer "${endpoint}"`
                + ` ${headerString}`
                + (authHeader ? ` ${authHeader}` : "")
                + ` --data '${CF.StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'`
                + "\n"
            
            /* Send the request */
            const scriptContent = requester.currentStrategy.finalizeScriptContent(scriptShebang + scriptFileSetupContent + scriptRequestContent)
            const shellScriptPath = CF.FileUtils.trimFileProtocol(root.requestScriptFilePath)
            requesterScriptFile.path = Qt.resolvedUrl(shellScriptPath)
            requesterScriptFile.setText(scriptContent)
            requester.command = baseCommand.concat([shellScriptPath]);
            requester.running = true
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return;
                if (requester.message.thinking) requester.message.thinking = false;
                // console.log("[Ai] Raw response line: ", data);

                // Handle response line
                try {
                    const result = requester.currentStrategy.parseResponseLine(data, requester.message);
                    // console.log("[Ai] Parsed response result: ", JSON.stringify(result, null, 2));

                    if (result.functionCall) {
                        requester.message.functionCall = result.functionCall;
                        root.handleFunctionCall(result.functionCall.name, result.functionCall.args, requester.message);
                    }
                    if (result.tokenUsage) {
                        root.tokenCount.input = result.tokenUsage.input;
                        root.tokenCount.output = result.tokenUsage.output;
                        root.tokenCount.total = result.tokenUsage.total;
                    }
                    if (result.finished) {
                        requester.markDone();
                    }
                    
                } catch (e) {
                    console.log("[AI] Could not parse response: ", e);
                    requester.message.rawContent += data;
                    requester.message.content += data;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            const result = requester.currentStrategy.onRequestFinished(requester.message);
            
            if (result.finished) {
                requester.markDone();
            } else if (!requester.message.done) {
                requester.markDone();
            }

            // Handle error responses
            if (requester.message.content.includes("API key not valid")) {
                root.addApiKeyAdvice(models[requester.message.model]);
            }
        }
    }

    function sendUserMessage(message) {
        if (message.length === 0) return;
        if (root.pendingFilePath.length > 0 && root.getModel()?.api_format !== "gemini_cli") {
            root.addMessage(
                Translation.tr("Attached screenshots currently work only with Gemini CLI. Switch to `gemini-cli` or remove the attachment first."),
                root.interfaceRole
            );
            return;
        }

        const userMessage = root.aiMessageComponent.createObject(root, {
            "role": "user",
            "content": message,
            "rawContent": message,
            "localFilePath": root.pendingFilePath,
            "thinking": false,
            "done": true,
        });
        const id = idForMessage(userMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = userMessage;
        requester.makeRequest();
    }

    function attachFile(filePath: string) {
        root.pendingFilePath = CF.FileUtils.trimFileProtocol(filePath);
    }

    function regenerate(messageIndex) {
        if (messageIndex < 0 || messageIndex >= messageIDs.length) return;
        const id = root.messageIDs[messageIndex];
        const message = root.messageByID[id];
        if (message.role !== "assistant") return;
        // Remove all messages after this one
        for (let i = root.messageIDs.length - 1; i >= messageIndex; i--) {
            root.removeMessage(i);
        }
        requester.makeRequest();
    }

    function createFunctionOutputMessage(name, output, includeOutputInChat = true) {
        return aiMessageComponent.createObject(root, {
            "role": "user",
            "content": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "rawContent": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "functionName": name,
            "functionResponse": output,
            "thinking": false,
            "done": true,
            // "visibleToUser": false,
        });
    }

    function addFunctionOutputMessage(name, output) {
        const aiMessage = createFunctionOutputMessage(name, output);
        const id = idForMessage(aiMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = aiMessage;
    }

    function rejectCommand(message: AiMessageData) {
        if (!message.functionPending) return;
        message.functionPending = false; // User decided, no more "thinking"
        addFunctionOutputMessage(message.functionName, Translation.tr("Command rejected by user"))
    }

    function approveCommand(message: AiMessageData) {
        if (!message.functionPending) return;
        message.functionPending = false; // User decided, no more "thinking"

        const responseMessage = createFunctionOutputMessage(message.functionName, "", false);
        const id = idForMessage(responseMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = responseMessage;

        commandExecutionProc.message = responseMessage;
        commandExecutionProc.baseMessageContent = responseMessage.content;
        commandExecutionProc.shellCommand = message.functionCall.args.command;
        commandExecutionProc.running = true; // Start the command execution
    }

    Process {
        id: commandExecutionProc
        property string shellCommand: ""
        property AiMessageData message
        property string baseMessageContent: ""
        command: ["bash", "-c", shellCommand]
        stdout: SplitParser {
            onRead: (output) => {
                commandExecutionProc.message.functionResponse += output + "\n\n";
                const updatedContent = commandExecutionProc.baseMessageContent + `\n\n<think>\n<tt>${commandExecutionProc.message.functionResponse}</tt>\n</think>`;
                commandExecutionProc.message.rawContent = updatedContent;
                commandExecutionProc.message.content = updatedContent;
            }
        }
        onExited: (exitCode, exitStatus) => {
            commandExecutionProc.message.functionResponse += `[[ Command exited with code ${exitCode} (${exitStatus}) ]]\n`;
            requester.makeRequest(); // Continue
        }
    }

    function handleFunctionCall(name, args: var, message: AiMessageData) {
        if (name === "switch_to_search_mode") {
            const modelId = root.currentModelId;
            root.currentTool = "search"
            root.postResponseHook = () => { root.currentTool = "functions" }
            addFunctionOutputMessage(name, Translation.tr("Switched to search mode. Continue with the user's request."))
            requester.makeRequest();
        } else if (name === "get_shell_config") {
            const configJson = CF.ObjectUtils.toPlainObject(Config.options)
            addFunctionOutputMessage(name, JSON.stringify(configJson));
            requester.makeRequest();
        } else if (name === "set_shell_config") {
            if (!args.key || !args.value) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `key` and `value`."));
                return;
            }
            const key = args.key;
            const value = args.value;
            Config.setNestedValue(key, value);
        } else if (name === "run_shell_command") {
            if (!args.command || args.command.length === 0) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `command`."));
                return;
            }
            const contentToAppend = `\n\n**Command execution request**\n\n\`\`\`command\n${args.command}\n\`\`\``;
            message.rawContent += contentToAppend;
            message.content += contentToAppend;
            message.functionPending = true; // Use thinking to indicate the command is waiting for approval
        }
        else root.addMessage(Translation.tr("Unknown function call: %1").arg(name), "assistant");
    }

    function chatToJson() {
        return root.messageIDs.map(id => {
            const message = root.messageByID[id]
            return ({
                "role": message.role,
                "rawContent": message.rawContent,
                "fileMimeType": message.fileMimeType,
                "fileUri": message.fileUri,
                "localFilePath": message.localFilePath,
                "model": message.model,
                "thinking": false,
                "done": true,
                "annotations": message.annotations,
                "annotationSources": message.annotationSources,
                "functionName": message.functionName,
                "functionCall": message.functionCall,
                "functionResponse": message.functionResponse,
                "visibleToUser": message.visibleToUser,
            })
        })
    }

    FileView {
        id: chatSaveFile
        property string chatName: ""
        path: chatName.length > 0 ? `${Directories.aiChats}/${chatName}.json` : ""
        blockLoading: true // Prevent race conditions
    }

    /**
     * Saves chat to a JSON list of message objects.
     * @param chatName name of the chat
     */
    function saveChat(chatName) {
        chatSaveFile.chatName = chatName.trim()
        const saveContent = JSON.stringify(root.chatToJson())
        chatSaveFile.setText(saveContent)
        getSavedChats.running = true;
    }

    /**
     * Loads chat from a JSON list of message objects.
     * @param chatName name of the chat
     */
    function loadChat(chatName) {
        try {
            chatSaveFile.chatName = chatName.trim()
            chatSaveFile.reload()
            const saveContent = chatSaveFile.text()
            // console.log(saveContent)
            const saveData = JSON.parse(saveContent)
            root.clearMessages()
            root.messageIDs = saveData.map((_, i) => {
                return i
            })
            // console.log(JSON.stringify(messageIDs))
            for (let i = 0; i < saveData.length; i++) {
                const message = saveData[i];
                root.messageByID[i] = root.aiMessageComponent.createObject(root, {
                    "role": message.role,
                    "rawContent": message.rawContent,
                    "content": message.rawContent,
                    "fileMimeType": message.fileMimeType,
                    "fileUri": message.fileUri,
                    "localFilePath": message.localFilePath,
                    "model": message.model,
                    "thinking": message.thinking,
                    "done": message.done,
                    "annotations": message.annotations,
                    "annotationSources": message.annotationSources,
                    "functionName": message.functionName,
                    "functionCall": message.functionCall,
                    "functionResponse": message.functionResponse,
                    "visibleToUser": message.visibleToUser,
                });
            }
        } catch (e) {
            console.log("[AI] Could not load chat: ", e);
        } finally {
            getSavedChats.running = true;
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

/**
 * Basic service to handle LLM chats. Supports Google's and OpenAI's API formats.
 */
Singleton {
    id: root

    readonly property string interfaceRole: "interface"
    readonly property string apiKeyEnvVarName: "API_KEY"
    property Component aiMessageComponent: AiMessageData {}
    property string systemPrompt: ConfigOptions?.ai?.systemPrompt ?? ""
    property var messages: []
    property var messageIDs: []
    property var messageByID: ({})
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}
    readonly property var apiKeysLoaded: KeyringStorage.loaded
    property var postResponseHook
    property real temperature: PersistentStates?.ai?.temperature ?? 0.5

    function idForMessage(message) {
        // Generate a unique ID using timestamp and random value
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    function safeModelName(modelName) {
        return modelName.replace(/:/g, "_").replace(/\./g, "_")
    }

    // Model properties:
    // - name: Name of the model
    // - icon: Icon name of the model
    // - description: Description of the model
    // - endpoint: Endpoint of the model
    // - model: Model name of the model
    // - requires_key: Whether the model requires an API key
    // - key_id: The identifier of the API key. Use the same identifier for models that can be accessed with the same key.
    // - key_get_link: Link to get an API key
    // - key_get_description: Description of pricing and how to get an API key
    // - api_format: The API format of the model. Can be "openai" or "gemini". Default is "openai".
    // - tools: List of tools that the model can use. Each tool is an object with the tool name as the key and an empty object as the value.
    // - extraParams: Extra parameters to be passed to the model. This is a JSON object.
    property var models: {
        "gemini-2.0-flash-search": {
            "name": "Gemini 2.0 Flash (Search)",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nGives up-to-date information with search."),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent",
            "model": "gemini-2.0-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini",
            "tools": [
                {
                    "google_search": {}
                },
            ]
        },
        "gemini-2.0-flash-tools": {
            "name": "Gemini 2.0 Flash (Tools)",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Experimental | Online | Google's model\nCan do a little more but doesn't search quickly"),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent",
            "model": "gemini-2.0-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini",
            "tools": [
                {
                    "functionDeclarations": [
                        {
                            "name": "switch_to_search_mode",
                            "description": "Search the web",
                        },
                        {
                            "name": "get_shell_config",
                            "description": "Get the desktop shell config file contents",
                        },
                        {
                            "name": "set_shell_config",
                            "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "key": {
                                        "type": "string",
                                        "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting.",
                                    },
                                    "value": {
                                        "type": "string",
                                        "description": "The value to set, e.g. `true`"
                                    }
                                },
                                "required": ["key", "value"]
                            }
                        },
                    ]
                }
            ]
        },
        "gemini-2.5-flash-search": {
            "name": "Gemini 2.5 Flash (Search)",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Online | Google's model\nGives up-to-date information with search."),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:streamGenerateContent",
            "model": "gemini-2.5-flash-preview-05-20",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini",
            "tools": [
                {
                    "google_search": ({})
                },
            ]
        },
        "gemini-2.5-flash-tools": {
            "name": "Gemini 2.5 Flash (Tools)",
            "icon": "google-gemini-symbolic",
            "description": qsTr("Experimental | Online | Google's model\nCan do a little more but doesn't search quickly"),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:streamGenerateContent",
            "model": "gemini-2.5-flash-preview-05-20",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": qsTr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini",
            "tools": [
                {
                    "functionDeclarations": [
                        {
                            "name": "switch_to_search_mode",
                            "description": "Search the web",
                        },
                        {
                            "name": "get_shell_config",
                            "description": "Get the desktop shell config file contents",
                        },
                        {
                            "name": "set_shell_config",
                            "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "key": {
                                        "type": "string",
                                        "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting.",
                                    },
                                    "value": {
                                        "type": "string",
                                        "description": "The value to set, e.g. `true`"
                                    }
                                },
                                "required": ["key", "value"]
                            }
                        },
                    ]
                }
            ]
        },
        "openrouter-llama4-maverick": {
            "name": "Llama 4 Maverick",
            "icon": "ollama-symbolic",
            "description": StringUtils.format(qsTr("Online via {0} | {1}'s model"), "OpenRouter", "Meta"),
            "homepage": "https://openrouter.ai/meta-llama/llama-4-maverick:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "meta-llama/llama-4-maverick:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
            "key_get_description": qsTr("**Pricing**: free. Data use policy varies depending on your OpenRouter account settings.\n\n**Instructions**: Log into OpenRouter account, go to Keys on the topright menu, click Create API Key"),
        },
        "openrouter-deepseek-r1": {
            "name": "DeepSeek R1",
            "icon": "deepseek-symbolic",
            "description": StringUtils.format(qsTr("Online via {0} | {1}'s model"), "OpenRouter", "DeepSeek"),
            "homepage": "https://openrouter.ai/deepseek/deepseek-r1:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "deepseek/deepseek-r1:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
            "key_get_description": qsTr("**Pricing**: free. Data use policy varies depending on your OpenRouter account settings.\n\n**Instructions**: Log into OpenRouter account, go to Keys on the topright menu, click Create API Key"),
        },
    }
    property var modelList: Object.keys(root.models)
    property var currentModelId: PersistentStates?.ai?.model || modelList[0]

    Component.onCompleted: {
        setModel(currentModelId, false); // Do necessary setup for model
        getOllamaModels.running = true
    }

    function guessModelLogo(model) {
        if (model.includes("llama")) return "ollama-symbolic";
        if (model.includes("gemma")) return "google-gemini-symbolic";
        if (model.includes("deepseek")) return "deepseek-symbolic";
        if (/^phi\d*:/i.test(model)) return "microsoft-symbolic";
        return "ollama-symbolic";
    }

    function guessModelName(model) {
        const replaced = model.replace(/-/g, ' ').replace(/:/g, ' ');
        let words = replaced.split(' ');
        words[words.length - 1] = words[words.length - 1].replace(/(\d+)b$/, (_, num) => `${num}B`)
        words = words.map((word) => {
            return (word.charAt(0).toUpperCase() + word.slice(1))
        });
        if (words[words.length - 1] === "Latest") words.pop();
        else words[words.length - 1] = `(${words[words.length - 1]})`; // Surround the last word with square brackets
        const result = words.join(' ');
        return result;
    }

    Process {
        id: getOllamaModels
        command: ["bash", "-c", `${Directories.config}/quickshell/scripts/ai/show-installed-ollama-models.sh`.replace(/file:\/\//, "")]
        stdout: SplitParser {
            onRead: data => {
                try {
                    if (data.length === 0) return;
                    const dataJson = JSON.parse(data);
                    root.modelList = [...root.modelList, ...dataJson];
                    dataJson.forEach(model => {
                        const safeModelName = root.safeModelName(model);
                        root.models[safeModelName] = {
                            "name": guessModelName(model),
                            "icon": guessModelLogo(model),
                            "description": StringUtils.format(qsTr("Local Ollama model | {0}"), model),
                            "homepage": `https://ollama.com/library/${model}`,
                            "endpoint": "http://localhost:11434/v1/chat/completions",
                            "model": model,
                        }
                    });

                    root.modelList = Object.keys(root.models);

                } catch (e) {
                    console.log("Could not fetch Ollama models:", e);
                }
            }
        }
    }

    function addMessage(message, role) {
        if (message.length === 0) return;
        const aiMessage = aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
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
            StringUtils.format(qsTr('To set an API key, pass it with the command\n\nTo view the key, pass "get" with the command<br/>\n\n### For {0}:\n\n**Link**: {1}\n\n{2}'), 
                model.name, model.key_get_link, model.key_get_description ?? qsTr("<i>No further instruction provided</i>")), 
            Ai.interfaceRole
        );
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId, feedback = true) {
        if (!modelId) modelId = ""
        modelId = modelId.toLowerCase()
        if (modelList.indexOf(modelId) !== -1) {
            const model = models[modelId]
            // Fetch API keys if needed
            if (model?.requires_key) KeyringStorage.fetchKeyringData();
            // See if policy prevents online models
            if (ConfigOptions.policies.ai === 2 && !model.endpoint.includes("localhost")) {
                root.addMessage(StringUtils.format(StringUtils.format("Online models disallowed\n\nControlled by `policies.ai` config option"), model.name), root.interfaceRole);
                return;
            }
            PersistentStateManager.setState("ai.model", modelId);
            if (feedback) root.addMessage(StringUtils.format(StringUtils.format("Model set to {0}"), model.name), root.interfaceRole);
            if (model.requires_key) {
                // If key not there show advice
                if (root.apiKeysLoaded && (!root.apiKeys[model.key_id] || root.apiKeys[model.key_id].length === 0)) {
                    root.addApiKeyAdvice(model)
                }
            }
        } else {
            if (feedback) root.addMessage(qsTr("Invalid model. Supported: \n```\n") + modelList.join("\n```\n```\n"), Ai.interfaceRole) + "\n```"
        }
    }
    
    function getTemperature() {
        return root.temperature;
    }

    function setTemperature(value) {
        if (value == NaN || value < 0 || value > 2) {
            root.addMessage(qsTr("Temperature must be between 0 and 2"), Ai.interfaceRole);
            return;
        }
        PersistentStateManager.setState("ai.temperature", value);
        root.temperature = value;
        root.addMessage(StringUtils.format(qsTr("Temperature set to {0}"), value), Ai.interfaceRole);
    }

    function setApiKey(key) {
        const model = models[currentModelId];
        if (!model.requires_key) {
            root.addMessage(StringUtils.format(qsTr("{0} does not require an API key"), model.name), Ai.interfaceRole);
            return;
        }
        if (!key || key.length === 0) {
            const model = models[currentModelId];
            root.addApiKeyAdvice(model)
            return;
        }
        KeyringStorage.setNestedField(["apiKeys", model.key_id], key.trim());
        root.addMessage(StringUtils.format(qsTr("API key set for {0}"), model.name, Ai.interfaceRole));
    }

    function printApiKey() {
        const model = models[currentModelId];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage(StringUtils.format(qsTr("API key:\n\n```txt\n{0}\n```"), key), Ai.interfaceRole);
            } else {
                root.addMessage(StringUtils.format(qsTr("No API key set for {0}"), model.name), Ai.interfaceRole);
            }
        } else {
            root.addMessage(StringUtils.format(qsTr("{0} does not require an API key"), model.name), Ai.interfaceRole);
        }
    }

    function printTemperature() {
        root.addMessage(StringUtils.format(qsTr("Temperature: {0}"), root.temperature), Ai.interfaceRole);
    }

    function clearMessages() {
        root.messageIDs = [];
        root.messageByID = ({});
    }

    Process {
        id: requester
        property var baseCommand: ["bash", "-c"]
        property var message
        property bool isReasoning
        property string apiFormat: "openai"
        property string geminiBuffer: ""

        function buildGeminiEndpoint(model) {
            // console.log("ENDPOINT: " + model.endpoint + `?key=\$\{${root.apiKeyEnvVarName}\}`)
            return model.endpoint + `?key=\$\{${root.apiKeyEnvVarName}\}`;
        }

        function buildOpenAIEndpoint(model) {
            return model.endpoint;
        }

        function markDone() {
            requester.message.done = true;
            if (root.postResponseHook) {
                root.postResponseHook();
                root.postResponseHook = null; // Reset hook after use
            }
        }

        function buildGeminiRequestData(model, messages) {
            let baseData = {
                "contents": messages.filter(message => (message.role != Ai.interfaceRole)).map(message => {
                    const geminiApiRoleName = (message.role === "assistant") ? "model" : message.role;
                    const usingSearch = model.tools[0].google_search != undefined                
                    if (!usingSearch && message.functionCall != undefined && message.functionCall.length > 0) {
                        return {
                            "role": geminiApiRoleName,
                            "parts": [{ 
                                functionCall: {
                                    "name": message.functionName,
                                }
                            }]
                        }
                    }
                    if (!usingSearch && message.functionResponse != undefined && message.functionResponse.length > 0) {
                        return {
                            "role": geminiApiRoleName,
                            "parts": [{ 
                                functionResponse: {
                                    "name": message.functionName,
                                    "response": { "content": message.functionResponse }
                                }
                            }]
                        }
                    }
                    return {
                        "role": geminiApiRoleName,
                        "parts": [{ 
                            text: message.content,
                        }]
                    }
                }),
                "tools": [
                    ...model.tools,
                ],
                "system_instruction": {
                    "parts": [{ text: root.systemPrompt }]
                },
                "generationConfig": {
                    // "temperature": root.temperature,
                },
            };
            return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
        }

        function buildOpenAIRequestData(model, messages) {
            let baseData = {
                "model": model.model,
                "messages": [
                    {role: "system", content: root.systemPrompt},
                    ...messages.filter(message => (message.role != Ai.interfaceRole)).map(message => {
                        return {
                            "role": message.role,
                            "content": message.content,
                        }
                    }),
                ],
                "stream": true,
                // "temperature": root.temperature,
            };
            return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
        }

        function makeRequest() {
            const model = models[currentModelId];
            requester.apiFormat = model.api_format ?? "openai";

            /* Put API key in environment variable */
            if (model.requires_key) requester.environment[`${root.apiKeyEnvVarName}`] = root.apiKeys ? (root.apiKeys[model.key_id] ?? "") : ""

            /* Build endpoint, request data */
            const endpoint = (apiFormat === "gemini") ? buildGeminiEndpoint(model) : buildOpenAIEndpoint(model);
            const messageArray = root.messageIDs.map(id => root.messageByID[id]);
            const data = (apiFormat === "gemini") ? buildGeminiRequestData(model, messageArray) : buildOpenAIRequestData(model, messageArray);
            // console.log("REQUEST DATA: ", JSON.stringify(data, null, 2));

            let requestHeaders = {
                "Content-Type": "application/json",
            }
            
            /* Create local message object */
            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "thinking": true,
                "done": false,
            });
            const id = idForMessage(requester.message);
            root.messageIDs = [...root.messageIDs, id];
            root.messageByID[id] = requester.message;

            /* Build header string for curl */ 
            let headerString = Object.entries(requestHeaders)
                .filter(([k, v]) => v && v.length > 0)
                .map(([k, v]) => `-H '${k}: ${v}'`)
                .join(' ');

            // console.log("Request headers: ", JSON.stringify(requestHeaders));
            // console.log("Header string: ", headerString);

            /* Create command string */
            const requestCommandString = `curl --no-buffer "${endpoint}"`
                + ` ${headerString}`
                + ((apiFormat == "gemini") ? "" : ` -H "Authorization: Bearer \$\{${root.apiKeyEnvVarName}\}"`)
                + ` -d '${StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'`
            // console.log("Request command: ", requestCommandString);
            requester.command = baseCommand.concat([requestCommandString]);

            /* Reset vars and make the request */
            requester.isReasoning = false
            requester.running = true
        }

        function parseGeminiBuffer() {
            // console.log("BUFFER DATA: ", requester.geminiBuffer);
            try {
                if (requester.geminiBuffer.length === 0) return;
                const dataJson = JSON.parse(requester.geminiBuffer);
                if (!dataJson.candidates) return;
                
                if (dataJson.candidates[0]?.finishReason) {
                    requester.markDone();
                }
                // Function call handling
                if (dataJson.candidates[0]?.content?.parts[0]?.functionCall) {
                    const functionCall = dataJson.candidates[0]?.content?.parts[0]?.functionCall;
                    requester.message.functionName = functionCall.name;
                    requester.message.functionCall = functionCall.name;
                    requester.message.content += `\n\n[[ Function: ${functionCall.name}(${JSON.stringify(functionCall.args, null, 2)}) ]]\n`;
                    root.handleGeminiFunctionCall(functionCall.name, functionCall.args);
                    return
                }
                // Normal text response
                const responseContent = dataJson.candidates[0]?.content?.parts[0]?.text
                requester.message.content += responseContent;
                const annotationSources = dataJson.candidates[0]?.groundingMetadata?.groundingChunks?.map(chunk => {
                    return {
                        "type": "url_citation",
                        "text": chunk?.web?.title,
                        "url": chunk?.web?.uri,
                    }
                });
                const annotations = dataJson.candidates[0]?.groundingMetadata?.groundingSupports?.map(citation => {
                    return {
                        "type": "url_citation",
                        "start_index": citation.segment?.startIndex,
                        "end_index": citation.segment?.endIndex,
                        "text": citation?.segment.text,
                        "url": annotationSources[citation.groundingChunkIndices[0]]?.url,
                        "sources": citation.groundingChunkIndices
                    }
                });
                requester.message.annotationSources = annotationSources;
                requester.message.annotations = annotations;
                // console.log(JSON.stringify(requester.message, null, 2));
            } catch (e) {
                console.log("[AI] Could not parse response from stream: ", e);
                requester.message.content += requester.geminiBuffer
            } finally {
                requester.geminiBuffer = "";
            }
        }

        function handleGeminiResponseLine(line) {
            if (line.startsWith("[")) {
                requester.geminiBuffer += line.slice(1).trim();
            } else if (line == "]") {
                requester.geminiBuffer += line.slice(0, -1).trim();
                parseGeminiBuffer();
            } else if (line.startsWith(",")) { // end of one entry 
                parseGeminiBuffer();
            } else {
                requester.geminiBuffer += line.trim();
            }
        }

        function handleOpenAIResponseLine(line) {
            // Remove 'data: ' prefix if present and trim whitespace
            let cleanData = line.trim();
            if (cleanData.startsWith("data:")) {
                cleanData = cleanData.slice(5).trim();
            }
            // console.log("Clean data: ", cleanData);
            if (!cleanData || cleanData.startsWith(":")) return;

            if (cleanData === "[DONE]") {
                requester.markDone();
                return;
            }
            const dataJson = JSON.parse(cleanData);

            let newContent = "";
            const responseContent = dataJson.choices[0]?.delta?.content || dataJson.message?.content;
            const responseReasoning = dataJson.choices[0]?.delta?.reasoning || dataJson.choices[0]?.delta?.reasoning_content;

            if (responseContent && responseContent.length > 0) {
                if (requester.isReasoning) {
                    requester.isReasoning = false;
                    requester.message.content += "\n\n</think>\n\n";
                }
                newContent = dataJson.choices[0]?.delta?.content || dataJson.message.content;
            } else if (responseReasoning && responseReasoning.length > 0) {
                // console.log("Reasoning content: ", dataJson.choices[0].delta.reasoning);
                if (!requester.isReasoning) {
                    requester.isReasoning = true;
                    requester.message.content += "\n\n<think>\n\n";
                } 
                newContent = dataJson.choices[0].delta.reasoning || dataJson.choices[0].delta.reasoning_content;
            }

            requester.message.content += newContent;

            if (dataJson.done) {
                requester.markDone();
            }
        }

        stdout: SplitParser {
            onRead: data => {
                // console.log("RAW DATA: ", data);
                if (data.length === 0) return;

                // Handle response line
                if (requester.message.thinking) requester.message.thinking = false;
                try {
                    if (requester.apiFormat === "gemini") {
                        requester.handleGeminiResponseLine(data);
                    }
                    else if (requester.apiFormat === "openai") {
                        requester.handleOpenAIResponseLine(data);
                    }
                    else {
                        console.log("Unknown API format: ", requester.apiFormat);
                        requester.message.content += data;
                    }
                } catch (e) {
                    console.log("[AI] Could not parse response from stream: ", e);
                    requester.message.content += data;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (requester.apiFormat == "gemini") requester.parseGeminiBuffer();
            else requester.markDone();

            try { // to parse full response into json for error handling
                // console.log("Full response: ", requester.message.content + "]"); 
                const parsedResponse = JSON.parse(requester.message.content + "]");
                requester.message.content = `\`\`\`json\n${JSON.stringify(parsedResponse, null, 2)}\n\`\`\``;
            } catch (e) { 
                // console.log("[AI] Could not parse response on exit: ", e);
            }

            if (requester.message.content.includes("API key not valid")) {
                root.addApiKeyAdvice(models[requester.message.model]);
            }
        }
    }

    function sendUserMessage(message) {
        if (message.length === 0) return;
        root.addMessage(message, "user");
        requester.makeRequest();
    }

    function addFunctionOutputMessage(name, output) {
        const aiMessage = aiMessageComponent.createObject(root, {
            "role": "user",
            "content": `[[ Output of ${name} ]]`,
            "functionName": name,
            "functionResponse": output,
            "thinking": false,
            "done": true,
            "visibleToUser": false,
        });
        // console.log("Adding function output message: ", JSON.stringify(aiMessage));
        const id = idForMessage(aiMessage);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = aiMessage;
    }

    function buildGeminiFunctionOutput(name, output) {
        const functionResponsePart = {
            "name": name,
            "response": { "content": output }
        }
        return {
            "role": "user",
            "parts": [{ 
                functionResponse: functionResponsePart,
            }]
        }
    }

    function handleGeminiFunctionCall(name, args) {
        if (name === "switch_to_search_mode") {
            if (root.currentModelId === "gemini-2.5-flash-tools") {
                root.setModel("gemini-2.5-flash-search", false);
                root.postResponseHook = () => root.setModel("gemini-2.5-flash-tools", false);
            } else if (root.currentModelId === "gemini-2.0-flash-tools") {
                root.setModel("gemini-2.0-flash-search", false);
                root.postResponseHook = () => root.setModel("gemini-2.0-flash-tools", false);
            }
            addFunctionOutputMessage(name, qsTr("Switched to search mode. Continue with the user's request."))
            requester.makeRequest();
        } else if (name === "get_shell_config") {
            const configJson = ObjectUtils.toPlainObject(ConfigOptions)
            addFunctionOutputMessage(name, JSON.stringify(configJson));
            requester.makeRequest();
        } else if (name === "set_shell_config") {
            if (!args.key || !args.value) {
                addFunctionOutputMessage(name, qsTr("Invalid arguments. Must provide `key` and `value`."));
                return;
            }
            const key = args.key;
            const value = args.value;
            ConfigLoader.setLiveConfigValue(key, value);
            ConfigLoader.saveConfig();
        }
        else root.addMessage(qsTr("Unknown function call: {0}"), "assistant");
    }

}

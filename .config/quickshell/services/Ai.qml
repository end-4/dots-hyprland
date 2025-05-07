pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Singleton {
    id: root

    readonly property string xdgConfigHome: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string interfaceRole: "interface"
    property Component aiMessageComponent: AiMessageData {}
    property var messages: []
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}

    // Model properties:
    // - name: Name of the model
    // - icon: Icon name of the model
    // - description: Description of the model
    // - endpoint: Endpoint of the model
    // - model: Model name of the model
    // - requires_key: Whether the model requires an API key
    // - key_id: The identifier of the API key. Use the same identifier for models that can be accessed with the same key.
    // - key_get_link: Link to get the API key
    property var models: {
        "gemini-2.0-flash": {
            "name": "Gemini 2.0 Flash",
            "icon": "google-gemini-symbolic",
            "description": "Online | Google's model",
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            "model": "gemini-2.0-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            // "extraParams": {
            //     "tools": [
            //         {
            //             "google_search": {}
            //         }
            //     ]
            // }
        },
        "openrouter-llama4-maverick": {
            "name": "Llama 4 Maverick (OpenRouter)",
            "icon": "ollama-symbolic",
            "description": "Online | OpenRouter | Meta's model",
            "homepage": "https://openrouter.ai/meta-llama/llama-4-maverick:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "meta-llama/llama-4-maverick:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
        },
        "openrouter-deepseek-r1": {
            "name": "DeepSeek R1 (OpenRouter)",
            "icon": "deepseek-symbolic",
            "description": "Online | OpenRouter | DeepSeek's reasoning model",
            "homepage": "https://openrouter.ai/deepseek/deepseek-r1:free",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "deepseek/deepseek-r1:free",
            "requires_key": true,
            "key_id": "openrouter",
            "key_get_link": "https://openrouter.ai/settings/keys",
        },
    }
    property var modelList: Object.keys(root.models)
    property var currentModel: Object.keys(root.models)[0]

    Component.onCompleted: {
        setModel(currentModel, false); // Do necessary setup for model
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
        words[words.length - 1] = `[${words[words.length - 1]}]`; // Surround the last word with square brackets
        const result = words.join(' ');
        return result;
    }

    Process {
        id: getOllamaModels
        command: ["bash", "-c", `${xdgConfigHome}/quickshell/scripts/ai/show-installed-ollama-models.sh`.replace(/file:\/\//, "")]
        stdout: SplitParser {
            onRead: data => {
                try {
                    if (data.length === 0) return;
                    const dataJson = JSON.parse(data);
                    root.modelList = [...root.modelList, ...dataJson];
                    dataJson.forEach(model => {
                        root.models[model] = {
                            "name": guessModelName(model),
                            "icon": guessModelLogo(model),
                            "description": `Local (Ollama) | ${model}`,
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
        root.messages = [...root.messages, aiMessage];
    }

    function removeMessage(index) {
        if (index < 0 || index >= messages.length) return;
        root.messages.splice(index, 1);
        root.messages = [...root.messages];
    }

    function setModel(model, feedback = true) {
        if (!model) model = ""
        model = model.toLowerCase()
        if (modelList.indexOf(model) !== -1) {
            currentModel = model
            if (feedback) root.addMessage("Model set to " + models[model].name, Ai.interfaceRole)
        } else {
            if (feedback) root.addMessage(qsTr("Invalid model. Supported: \n- ") + modelList.join("\n- "), Ai.interfaceRole)
        }
        if (models[model].requires_key) {
            KeyringStorage.fetchKeyringData();
        } 
    }

    function setApiKey(key) {
        const model = models[currentModel];
        if (!model.requires_key) {
            root.addMessage(`${model.name} does not require an API key`, Ai.interfaceRole);
            return;
        }
        if (!key || key.length === 0) {
            root.addMessage(
                StringUtils.format(qsTr('To set an API key, pass it with the command\n\nTo view the key, pass "get" with the command<br/><br/>For {0}, you can grab one at:\n\n{1}'), 
                    models[currentModel].name, models[currentModel].key_get_link), 
                Ai.interfaceRole
            );
            return;
        }
        KeyringStorage.setNestedField(["apiKeys", model.key_id], key);
        root.addMessage("API key set for " + model.name, Ai.interfaceRole);
    }

    function printApiKey() {
        const model = models[currentModel];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage(StringUtils.format(qsTr("API key:\n\n`{0}`"), key), Ai.interfaceRole);
            } else {
                root.addMessage(StringUtils.format(qsTr("No API key set for {0}"), model.name), Ai.interfaceRole);
            }
        } else {
            root.addMessage(`This model (${model.name}) does not require an API key`, Ai.interfaceRole);
        }
    }

    function clearMessages() {
        messages = [];
    }

    Process {
        id: requester
        property var baseCommand: ["bash", "-c"]
        property var message
        property bool isReasoning

        function makeRequest() {
            const model = models[currentModel];
            let endpoint = model.endpoint;

            /* Build request data and headers */
            let baseData = {
                "model": model.model,
                "messages": root.messages.filter(message => (message.role != Ai.interfaceRole)).map(message => {
                    return {
                        "role": message.role,
                        "content": message.content,
                    }
                }),
                "stream": true,
            };
            let data = model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;

            
            let requestHeaders = {
                "Content-Type": "application/json",
            }

            /* Put API key in environment variable */
            if (model.requires_key) requester.environment = ({
                "API_KEY": root.apiKeys ? (root.apiKeys[model.key_id] ?? "") : "",
            })
            
            /* Create message object for local storage */
            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModel,
                "content": "",
                "thinking": true,
                "done": false,
            });
            root.messages = [...root.messages, requester.message];

            /* Build header string for curl */ 
            let headerString = Object.entries(requestHeaders)
                .filter(([k, v]) => v && v.length > 0)
                .map(([k, v]) => `-H '${k}: ${v}'`)
                .join(' ');

            // console.log("Request headers: ", JSON.stringify(requestHeaders));
            // console.log("Header string: ", headerString);

            /* Create command string */
            const requestCommandString = `curl --no-buffer '${endpoint}'`
                + ` ${headerString}`
                + ' -H "Authorization: Bearer ${API_KEY}"'
                + ` -d '${StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'`
            console.log("Request command: ", requestCommandString);
            requester.command = baseCommand.concat([requestCommandString]);

            /* Reset vars and make the request */
            requester.isReasoning = false
            requester.running = true
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return;

                // Remove 'data: ' prefix if present and trim whitespace
                let cleanData = data.trim();
                if (cleanData.startsWith("data:")) {
                    cleanData = cleanData.slice(5).trim();
                }
                // console.log("Clean data: ", cleanData);
                if (!cleanData ||
                    cleanData === ": OPENROUTER PROCESSING"
                ) return;

                if (requester.message.thinking) requester.message.thinking = false;
                try {
                    if (cleanData === "[DONE]") {
                        requester.message.done = true;
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

                    if (dataJson.done) requester.message.done = true;
                } catch (e) {
                    console.log("[AI] Could not parse response from stream: ", e);
                    requester.message.content += cleanData;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            try { // to parse full response into json
                // console.log("Full response: ", requester.message.content + "]"); 
                const parsedResponse = JSON.parse(requester.message.content + "]");
                requester.message.content = `\`\`\`json\n${JSON.stringify(parsedResponse, null, 2)}\n\`\`\``;
            } catch (e) { 
                console.log("[AI] Could not parse response on exit: ", e);
            }
        }
    }

    function sendUserMessage(message) {
        if (message.length === 0) return;

        const userMessage = aiMessageComponent.createObject(root, {
            "role": "user",
            "content": message,
            "thinking": false,
            "done": true,
        });
        root.messages = [...root.messages, userMessage];

        requester.makeRequest();
    }

}

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

    readonly property string interfaceRole: "interface"
    property Component aiMessageComponent: AiMessageData {}
    property var messages: []
    property var modelList: ["ollama-llama-3.2", "gemini-2.0-flash"]
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}

    // Model properties:
    // - name: Name of the model
    // - icon: Icon name of the model
    // - description: Description of the model
    // - endpoint: Endpoint of the model
    // - model: Model name of the model
    // - requires_key: Whether the model requires an API key
    // - key_id: The identifier of the API key. Use the same identifier for models that can be accessed with the same key.
    property var models: { // TODO: Auto-detect installed ollama models
        "interface": {
            "name": "Interface",
        },
        "ollama-llama-3.2": {
            "name": "Ollama - Llama 3.2",
            "icon": "ollama-symbolic",
            "description": "Local Ollama model - Llama 3.2",
            "endpoint": "http://localhost:11434/v1/chat/completions",
            "model": "llama3.2",
        },
        "gemini-2.0-flash": {
            "name": "Gemini 2.0 Flash",
            "icon": "google-gemini-symbolic",
            "description": "Online Gemini 2.0 Flash",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            "model": "gemini-2.0-flash",
            "requires_key": true,
            "key_id": "gemini",
        },
    }
    property var currentModel: "ollama-llama-3.2"

    Component.onCompleted: {
        setModel(currentModel, false); // Do necessary setup for model
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
        if (!key || key.length === 0) {
            root.addMessage("Please enter an API key with the command", Ai.interfaceRole);
            return;
        }
        const model = models[currentModel];
        if (model.requires_key) {
            KeyringStorage.setNestedField(["apiKeys", model.key_id], key);
            root.addMessage("API key set for " + model.name, Ai.interfaceRole);
        } else {
            root.addMessage(`This model (${model.name}) does not require an API key`, Ai.interfaceRole);
        }
    }

    function printApiKey() {
        const model = models[currentModel];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage("API key:\n\n- `" + key, Ai.interfaceRole + "`");
            } else {
                root.addMessage("No API key set for " + model.name, Ai.interfaceRole);
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
            console.log(JSON.stringify(root.apiKeys))
            console.log("Model:", model.key_id);
            console.log(root.apiKeys[model.key_id]);

            console.log("API key: ", requester.environment.API_KEY);
            
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

            console.log("Request headers: ", JSON.stringify(requestHeaders));
            console.log("Header string: ", headerString);

            /* Create command string */
            const requestCommandString = `curl --no-buffer '${endpoint}'`
                + ` ${headerString}`
                + ' -H "Authorization: Bearer ${API_KEY}"'
                + ` -d '${StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'`
            // const requestCommandString = 'notify-send "api key" "${API_KEY}" && curl'
            console.log("Request command: ", requestCommandString);
            requester.command = baseCommand.concat([requestCommandString]);
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
                console.log("Clean data: ", cleanData);
                if (!cleanData) return;

                if (requester.message.thinking) requester.message.thinking = false;
                try {
                    if (cleanData === "[DONE]") {
                        requester.message.done = true;
                        return;
                    }
                    const dataJson = JSON.parse(cleanData);
                    requester.message.content += 
                        (dataJson.message?.content) ?? // Ollama
                        (dataJson.choices[0]?.delta?.content) ?? // Normal 
                        (dataJson.choices[0]?.delta?.reasoning_content) // Deepseek thinking

                    if (dataJson.done) requester.message.done = true;
                } catch (e) {
                    console.log("Error parsing JSON: ", e);
                    requester.message.content += cleanData;
                }
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

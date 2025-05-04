pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property var messages: []
    property var modelList: ["ollama-llama-3.2", "gemini-2.0-flash"]
    property var models: { // TODO: Auto-detect installed ollama models
        "interface": {
            "name": "System",
        },
        "ollama-llama-3.2": {
            "name": "Ollama - Llama 3.2",
            "icon": "ollama-symbolic",
            "description": "Ollama - Llama 3.2",
            "endpoint": "http://localhost:11434/api/chat",
            "model": "llama3.2",
        },
        "gemini-2.0-flash": {
            "name": "Gemini 2.0 Flash",
            "icon": "gemini-symbolic",
            "description": "Gemini 2.0 Flash",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent",
            "model": "gemini-2.0-flash",
            "messageMapFunc": function (message) {
                return {
                    "role": message.role,
                    "parts": [{text: message.content}],
                }
            },
        },
    }
    property var currentModel: "ollama-llama-3.2"

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

    function setModel(model) {
        if (!model) model = ""
        model = model.toLowerCase()
        if (modelList.indexOf(model) !== -1) {
            currentModel = model
            root.addMessage("Model set to " + models[model].name, "interface")
        } else {
            root.addMessage(qsTr("Invalid model. Supported: \n- ") + modelList.join("\n- "), "interface")
        }
    }

    function clearMessages() {
        messages = [];
    }

    Process {
        id: requester
        property var baseCommand: ["curl", "--no-buffer"]
        property var message

        function makeRequest() {
            const model = models[currentModel];

            let endpoint = model.endpoint;

            // Build request data using OpenAI's format. If the model has a custom requestDataBuilder, use that instead.
            let data = model.requestDataBuilder ? model.requestDataBuilder(root.messages.filter(message => (message.role != "interface"))) : {
                "model": model.model,
                "messages": root.messages.filter(message => (message.role != "interface")).map(message => {
                    return { // Remove unecessary properties
                        "role": message.role,
                        "content": message.content,
                    }
                }),
            }
            
            let requestHeaders = {
                "Content-Type": "application/json",
                // "Authorization": model.endpoint.startsWith("http") ? "Bearer " + model.apiKey : "",
            }
            
            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModel,
                "content": "",
                "thinking": true,
                "done": false,
            });
            root.messages = [...root.messages, requester.message];
            requester.command = baseCommand.concat([endpoint, "-d", JSON.stringify(data)]);
            console.log("Request command: ", requester.command.join(" "));
            requester.running = true
        }

        stdout: SplitParser {
            onRead: data => {
                // console.log("Received data: ", data);
                if (data.length === 0) return;
                const dataJson = JSON.parse(data);
                if (requester.message.thinking) requester.message.thinking = false;

                requester.message.content += dataJson.message.content

                if (dataJson.done) requester.message.done = true;
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

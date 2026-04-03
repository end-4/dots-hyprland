import QtQuick

ApiStrategy {
    property string buffer: ""

    function buildEndpoint(model) {
        return ""
    }

    function buildRequestData(model, messages, systemPrompt, temperature, tools, filePath) {
        const transcript = [
            systemPrompt && systemPrompt.length > 0 ? `System:\n${systemPrompt}` : "",
            ...messages.map(message => {
                const role = message.role === "assistant" ? "Assistant" : "User";
                return `${role}:\n${message.rawContent}`;
            })
        ].filter(Boolean).join("\n\n---\n\n");

        return {
            prompt: transcript,
            cwd: model.extraParams?.cwd || "",
            approvalMode: model.extraParams?.approval_mode || "suggest",
        };
    }

    function buildAuthorizationHeader(apiKeyEnvVarName) {
        return ""
    }

    function parseResponseLine(line, message) {
        const clean = line.trim();
        if (!clean) return {};

        try {
            const data = JSON.parse(clean);
            const type = data.type || "";

            if (type === "item.completed" && data.item?.type === "agent_message") {
                const text = data.item?.text ?? "";
                if (text.length > 0) {
                    message.rawContent += text;
                    message.content += text;
                }
            } else if (type === "turn.completed") {
                return {
                    tokenUsage: {
                        input: data.usage?.input_tokens ?? -1,
                        output: data.usage?.output_tokens ?? -1,
                        total: ((data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0))
                    },
                    finished: true
                };
            } else if (data.type === "approval_request" && data.command) {
                message.functionName = "run_shell_command";
                message.functionCall = {
                    name: "run_shell_command",
                    args: { command: data.command }
                };
                const block = `\n\n**Command execution request**\n\n\`\`\`command\n${data.command}\n\`\`\``;
                message.rawContent += block;
                message.content += block;
                message.functionPending = true;
            } else if (data.done === true || type === "finished") {
                return { finished: true };
            }
        } catch (e) {
            // Ignore non-JSON lines from the CLI so log output does not pollute the chat.
        }

        return {};
    }

    function onRequestFinished(message) {
        return {};
    }

    function reset() {
        buffer = "";
    }

    function buildScriptFileSetup(filePath) {
        return "";
    }

    function finalizeScriptContent(scriptContent) {
        return scriptContent;
    }
}

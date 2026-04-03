import QtQuick

ApiStrategy {
    property string buffer: ""

    function buildEndpoint(model) {
        return ""
    }

    function buildRequestData(model, messages, systemPrompt, temperature, tools, filePath) {
        const transcriptParts = [
            systemPrompt && systemPrompt.length > 0 ? `System:\n${systemPrompt}` : "",
            ...messages.map(message => {
                const role = message.role === "assistant" ? "Assistant" : "User";
                return `${role}:\n${message.rawContent}`;
            })
        ];

        if (filePath && filePath.length > 0) {
            transcriptParts.push(
                `Attached file:\n@${filePath}\n\nUse the attached image or file as part of your answer. If it is a screenshot, describe what you see before giving help.`
            );
        }

        const transcript = transcriptParts.filter(Boolean).join("\n\n---\n\n");

        return {
            prompt: transcript,
            cwd: model.extraParams?.cwd || "",
            model: model.model || "",
            binaryPath: model.extraParams?.binary_path || "",
        };
    }

    function buildAuthorizationHeader(apiKeyEnvVarName) {
        return ""
    }

    function appendText(message, text) {
        if (!text || text.length === 0)
            return;
        message.rawContent += text;
        message.content += text;
    }

    function parseResponseLine(line, message) {
        const clean = line.trim();
        if (!clean)
            return {};

        try {
            const data = JSON.parse(clean);
            const type = data.type || "";
            const text = data.content
                ?? data.text
                ?? data.message?.content
                ?? data.response?.text
                ?? data.result?.text
                ?? data.candidate?.content?.parts?.[0]?.text
                ?? data.chunk?.text
                ?? "";

            if (type === "message" && data.role === "assistant") {
                appendText(message, text);
            } else if (type.includes("content") || type.includes("delta") || type.includes("chunk")) {
                appendText(message, text);
            } else if ((type.includes("result") || type.includes("final")) && text.length > 0) {
                if (message.content.length === 0 || !message.content.includes(text))
                    appendText(message, text);
            } else if (!type && text.length > 0) {
                appendText(message, text);
            }

            const stats = data.usage ?? data.stats;
            if (stats) {
                return {
                    tokenUsage: {
                        input: stats.input_tokens ?? stats.prompt_tokens ?? stats.input ?? -1,
                        output: stats.output_tokens ?? stats.completion_tokens ?? -1,
                        total: stats.total_tokens ?? -1
                    },
                    finished: data.done === true
                };
            }

            if (data.done === true || type === "finished" || type === "final_result" || type === "result") {
                return { finished: true };
            }
        } catch (e) {
            appendText(message, line + "\n");
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

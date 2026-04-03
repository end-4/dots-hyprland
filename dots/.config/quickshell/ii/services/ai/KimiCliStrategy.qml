import QtQuick

ApiStrategy {
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
                ?? data.result?.text
                ?? "";

            if (type === "message" && data.role === "assistant") {
                appendText(message, text);
            } else if ((type.includes("result") || type.includes("final")) && text.length > 0) {
                if (message.content.length === 0 || !message.content.includes(text))
                    appendText(message, text);
            }

            const stats = data.usage ?? data.stats;
            if (stats) {
                return {
                    tokenUsage: {
                        input: stats.input_tokens ?? stats.prompt_tokens ?? stats.input ?? -1,
                        output: stats.output_tokens ?? stats.completion_tokens ?? -1,
                        total: stats.total_tokens ?? -1
                    }
                };
            }

            if (data.done === true || type === "finished" || type === "result" || type === "final_result")
                return { finished: true };
        } catch (e) {
            // Ignore non-JSON lines from the CLI.
        }

        return {};
    }

    function onRequestFinished(message) {
        return {};
    }

    function reset() {}

    function buildScriptFileSetup(filePath) {
        return "";
    }

    function finalizeScriptContent(scriptContent) {
        return scriptContent;
    }
}

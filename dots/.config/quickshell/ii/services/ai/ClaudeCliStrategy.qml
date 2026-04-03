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
            model: model.model || "sonnet",
            binaryPath: model.extraParams?.binary_path || "",
            permissionMode: model.extraParams?.permission_mode || "plan",
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

    function extractContentText(content) {
        if (typeof content === "string")
            return content;
        if (Array.isArray(content))
            return content
                .filter(part => part?.type === "text" || part?.text)
                .map(part => part.text ?? "")
                .join("");
        return "";
    }

    function parseResponseLine(line, message) {
        const clean = line.trim();
        if (!clean)
            return {};

        try {
            const data = JSON.parse(clean);
            const type = data.type || "";

            if (type === "assistant") {
                const text = extractContentText(data.message?.content);
                appendText(message, text);
            } else if (type === "message" && data.message?.role === "assistant") {
                appendText(message, extractContentText(data.message?.content));
            } else if (type === "result") {
                appendText(message, data.result ?? "");
                return { finished: true };
            }
        } catch (e) {
            // Ignore non-JSON noise from the CLI.
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

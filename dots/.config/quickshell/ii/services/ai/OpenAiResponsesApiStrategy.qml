import QtQuick

ApiStrategy {
    property bool isReasoning: false

    function buildEndpoint(model: AiModel): string {
        // console.log("[AI] Endpoint: " + model.endpoint);
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let baseData = {
            "model": model.model,
            "instructions": systemPrompt,
            "input": [...messages.map(message => ({
                            role: message.role,
                            content: message.rawContent
                        }))],
            "stream": true,
            "tools": tools,
            "temperature": temperature
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "Authorization: Bearer \$\{${apiKeyEnvVarName}\}"`;
    }

    function parseResponseLine(line, message) {
        let cleanData = line.trim();
        // event line
        if (cleanData.startsWith("event:")) {
            return {};
        }

        // Remove 'data: ' prefix if present and trim whitespace
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        // console.log("[AI] OpenAI: Data:", cleanData);

        // Handle special cases
        if (!cleanData || cleanData.startsWith(":"))
            return {};

        // Real stuff
        try {
            const dataJson = JSON.parse(cleanData);

            // Error response handling
            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return {
                    finished: true
                };
            }

            let newContent = "";

            if (dataJson.type === "response.output_text.delta") {
                if (isReasoning) {
                    isReasoning = false;

                    const endBlock = "\n\n</think>\n\n";
                    message.content += endBlock;
                    message.rawContent += endBlock;
                }

                newContent = dataJson.delta ?? "";
            } else if (dataJson.type === "response.output_item.added") {
                if (dataJson.item.type === "reasoning") {
                    if (!isReasoning) {
                        isReasoning = true;

                        const startBlock = "\n\n<think>\n\n";
                        message.content += startBlock;
                        message.rawContent += startBlock;
                    }

                    newContent = dataJson.item.summary ?? "";
                }
            }

            message.content += newContent;
            message.rawContent += newContent;

            if (dataJson.type === "response.completed") {
                let result = {
                    finished: true
                };

                if (dataJson.response && dataJson.response.usage) {
                    const usage = dataJson.response.usage;
                    result.tokenUsage = {
                        input: usage.input_tokens ?? -1,
                        output: usage.output_tokens ?? -1,
                        total: usage.total_tokens ?? -1
                    };
                }
                return result;
            }
        } catch (e) {
            console.log("[AI] OpenAI: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }

        return {};
    }

    function onRequestFinished(message) {
        // OpenAI format doesn't need special finish handling
        return {};
    }

    function reset() {
        isReasoning = false;
    }
}

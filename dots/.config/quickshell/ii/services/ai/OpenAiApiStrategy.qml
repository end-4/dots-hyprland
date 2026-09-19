import QtQuick

ApiStrategy {
    property bool isReasoning: false
    // Accumulates streamed tool-call fragments by index. OpenAI-compatible APIs
    // (incl. Ollama, OpenRouter) stream a tool call across several SSE chunks:
    // the first carries id + function.name, later chunks append function.arguments.
    // We assemble them and emit a {functionCall} result so the shared
    // Ai.qml -> handleFunctionCall flow runs — same contract as the Gemini path.
    // This is what makes function calling work for local/OpenAI-format models.
    property var toolCallAcc: ({})

    function buildEndpoint(model: AiModel): string {
        // console.log("[AI] Endpoint: " + model.endpoint);
        return model.endpoint;
    }

    // Recover the model's actual tool call from the injected display marker
    // `[[ Function: name({json}) ]]`. The marker is the durable record of the
    // call — it lives in rawContent, so it survives chat save/load, whereas
    // message.functionCall does not.
    function extractToolCall(rawContent) {
        const m = /\[\[ Function: (\w+)\(([\s\S]*?)\) \]\]/.exec(rawContent || "");
        if (!m) return null;
        let args = m[2].trim();
        try { JSON.parse(args); } catch (e) { args = "{}"; }
        return { name: m[1], arguments: args };
    }

    // Remove ALL runtime-injected scaffolding from assistant display text so the
    // history the model reads is clean prose + structured tool_calls (below),
    // never a copyable card. Without this a weak 7B few-shots itself: it sees its
    // own past turn rendered as `[[ Function: … ]]` / a ```command```  fence and
    // reproduces that AS TEXT on the next command instead of emitting a real
    // tool call — the fence then renders like a request but has no
    // functionPending, so no Approve button appears (the "second command" bug).
    function stripScaffolding(content) {
        return (content || "")
            .replace(/\s*<think>[\s\S]*?<\/think>\s*/g, " ")
            .replace(/```command\n[\s\S]*?```/g, "")
            .replace(/\[\[ Function:[\s\S]*?\]\]/g, "")
            .replace(/\[\[ Output of[^\]]*\]\]/g, "")
            .replace(/\*\*Command execution request\*\*[^\n]*\n?/g, "")
            .replace(/\n{3,}/g, "\n\n")
            .trim();
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        // Build history with PROPER OpenAI tool semantics: an assistant turn that
        // called a tool carries a structured `tool_calls`, and its result comes
        // back as a `role:"tool"` message keyed by tool_call_id. Flattening tool
        // use into text markers (the old behavior) is exactly what taught the
        // model to imitate the marker instead of calling the tool.
        const history = [{ role: "system", content: systemPrompt }];
        let callSeq = 0;
        let lastToolCallId = null;
        for (let i = 0; i < messages.length; i++) {
            const message = messages[i];
            if (message.role === "assistant") {
                const tc = extractToolCall(message.rawContent);
                const text = stripScaffolding(message.rawContent);
                if (tc) {
                    const id = `call_${callSeq++}`;
                    lastToolCallId = id;
                    history.push({
                        role: "assistant",
                        content: text,
                        tool_calls: [{ id: id, type: "function", function: { name: tc.name, arguments: tc.arguments } }],
                    });
                } else {
                    history.push({ role: "assistant", content: text });
                }
            } else if (message.role === "user" && message.functionName && lastToolCallId) {
                // Function/command result — the model's tool observation.
                const out = (message.functionResponse && message.functionResponse.length > 0)
                    ? message.functionResponse
                    : stripScaffolding(message.rawContent);
                history.push({ role: "tool", tool_call_id: lastToolCallId, content: out });
                lastToolCallId = null;
            } else {
                history.push({ role: message.role, content: message.rawContent });
            }
        }
        let baseData = {
            "model": model.model,
            "messages": history,
            "stream": true,
            "tools": tools,
            "temperature": temperature,
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "Authorization: Bearer \$\{${apiKeyEnvVarName}\}"`;
    }

    function hasPendingToolCall() {
        return Object.keys(toolCallAcc).length > 0;
    }

    // Assemble the first accumulated tool call, render it into the message (same
    // visible marker as Gemini), reset the accumulator, and return the contract
    // result that Ai.qml turns into handleFunctionCall().
    function emitToolCall(message) {
        const keys = Object.keys(toolCallAcc);
        if (keys.length === 0) return { finished: true };
        const tc = toolCallAcc[keys[0]];
        let args = {};
        try {
            args = (tc.args && tc.args.length > 0) ? JSON.parse(tc.args) : {};
        } catch (e) {
            // Arguments not valid JSON (truncated / model glitch): surface raw so
            // the user sees what happened instead of a silent no-op.
            const warn = `\n\n[[ Tool call ${tc.name}: could not parse arguments: ${tc.args} ]]\n`;
            message.rawContent += warn;
            message.content += warn;
            toolCallAcc = ({});
            return { finished: true };
        }
        const newContent = `\n\n[[ Function: ${tc.name}(${JSON.stringify(args, null, 2)}) ]]\n`;
        message.rawContent += newContent;
        message.content += newContent;
        message.functionName = tc.name;
        message.functionCall = tc.name;
        toolCallAcc = ({}); // reset for the next turn
        return { functionCall: { name: tc.name, args: args }, finished: true };
    }

    function parseResponseLine(line, message) {
        // Remove 'data: ' prefix if present and trim whitespace
        let cleanData = line.trim();
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        // console.log("[AI] OpenAI: Data:", cleanData);

        // Handle special cases
        if (!cleanData || cleanData.startsWith(":")) return {};
        if (cleanData === "[DONE]") {
            // Flush a tool call that finished without an explicit finish_reason chunk.
            if (hasPendingToolCall()) return emitToolCall(message);
            return { finished: true };
        }

        // Real stuff
        try {
            const dataJson = JSON.parse(cleanData);

            // Error response handling
            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            const choice = dataJson.choices ? dataJson.choices[0] : undefined;
            const delta = choice?.delta;
            const finishReason = choice?.finish_reason;

            // Accumulate streamed tool-call fragments (by index)
            if (delta?.tool_calls) {
                for (const tc of delta.tool_calls) {
                    const idx = tc.index ?? 0;
                    if (!toolCallAcc[idx]) toolCallAcc[idx] = { name: "", args: "" };
                    if (tc.function?.name) toolCallAcc[idx].name = tc.function.name;
                    if (tc.function?.arguments) toolCallAcc[idx].args += tc.function.arguments;
                }
            }

            let newContent = "";

            const responseContent = delta?.content || dataJson.message?.content;
            const responseReasoning = delta?.reasoning || delta?.reasoning_content;

            if (responseContent && responseContent.length > 0) {
                if (isReasoning) {
                    isReasoning = false;
                    const endBlock = "\n\n</think>\n\n";
                    message.content += endBlock;
                    message.rawContent += endBlock;
                }
                newContent = responseContent;
            } else if (responseReasoning && responseReasoning.length > 0) {
                if (!isReasoning) {
                    isReasoning = true;
                    const startBlock = "\n\n<think>\n\n";
                    message.rawContent += startBlock;
                    message.content += startBlock;
                }
                newContent = responseReasoning;
            }

            message.content += newContent;
            message.rawContent += newContent;

            // A finished tool call: emit it so Ai.qml runs handleFunctionCall.
            if ((finishReason === "tool_calls" || finishReason) && hasPendingToolCall()) {
                return emitToolCall(message);
            }

            // Usage metadata
            if (dataJson.usage) {
                return {
                    tokenUsage: {
                        input: dataJson.usage.prompt_tokens ?? -1,
                        output: dataJson.usage.completion_tokens ?? -1,
                        total: dataJson.usage.total_tokens ?? -1
                    },
                    finished: !!finishReason
                };
            }

            if (dataJson.done || finishReason) {
                if (hasPendingToolCall()) return emitToolCall(message);
                return { finished: true };
            }

        } catch (e) {
            console.log("[AI] OpenAI: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }

        return {};
    }

    function onRequestFinished(message) {
        // Safety net: flush any tool call assembled but not yet emitted (e.g. the
        // stream ended without a [DONE] / finish_reason line).
        if (hasPendingToolCall()) return emitToolCall(message);
        return {};
    }

    function reset() {
        isReasoning = false;
        toolCallAcc = ({});
    }

}

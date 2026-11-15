import QtQuick
import qs.services
import qs.modules.common.functions as CF

/**
 * Claude via the Claude Code CLI (`claude -p`) run as a local process:
 * finalizeScriptContent() discards the assembled curl script, input goes over stdin
 * as stream-json, and conversation continuity uses CLI sessions (--resume).
 */
ApiStrategy {
    isCli: true
    // The request captured by buildRequestData: {model, messages, systemPrompt, filePath, sessionId}
    property var pendingRequest: null
    property bool inThinkingBlock: false
    // Command fences render at content_block_start and are rewritten in place by ordinal
    // while the input streams. Entries stay registered after the block stops because the
    // permission request refers back to them (and can even beat the stop)
    property string currentToolId: ""
    property var pendingTools: ({})
    property bool interruptRequested: false
    // A tool whose input is complete is running, unless it turns out to want approval first.
    // The permission request can trail the block's stop, so each tool waits out its own delay
    // before taking the label; one that settles inside the delay never shows it at all
    property int promotionDelay: 150
    // Kept small: the whole log is laid out at once when expanded, and it is saved with the chat
    property int maxOutputLines: 200
    property var promotionQueue: []
    property var promotionMessage: null
    property Timer promotionTimer: Timer {
        interval: 50
        repeat: true
        onTriggered: {
            const now = Date.now();
            promotionQueue = promotionQueue.filter(entry => {
                if (now < entry.due) return true;
                const tool = pendingTools[entry.id];
                if (tool && tool.state === "streaming") {
                    tool.state = "running";
                    tool.startedAt = now;
                    rewriteFence(promotionMessage, tool);
                }
                return false;
            });
            if (promotionQueue.length === 0) stop();
        }
    }

    function buildEndpoint(model: AiModel): string { return "" }
    function buildAuthorizationHeader(apiKeyEnvVarName: string): string { return "" }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools, filePath: string) {
        // Resume the newest session found in the chat; none means a fresh one
        const sessionId = messages.map(m => m.cliSessionId).filter(id => id && id.length > 0).pop() ?? "";
        pendingRequest = ({
            model: model,
            messages: messages,
            systemPrompt: systemPrompt,
            filePath: filePath,
            sessionId: sessionId,
        });
        return {};
    }

    // Written to the process's stdin by the service right after launch; stdin then
    // stays open for permission responses
    function buildStdinPayload(): string {
        const request = pendingRequest;
        // Resuming: only the newest message is sent, the session carries the rest.
        // Fresh session: serialize the whole chat so context survives model switches and loaded chats
        let prompt = request.sessionId.length > 0
            ? (request.messages[request.messages.length - 1]?.rawContent ?? "")
            : request.messages.map(m => `${m.role}: ${m.rawContent}`).join("\n\n");
        if (request.filePath && request.filePath.length > 0) {
            prompt += `\n\n[Attached file: ${request.filePath}]`;
        }
        return JSON.stringify({
            type: "user",
            message: { role: "user", content: [{ type: "text", text: prompt }] }
        });
    }

    // The CLI stops the turn gracefully and records it in the session, unlike a signal
    function buildInterruptRequest(): string {
        interruptRequested = true;
        return JSON.stringify({
            type: "control_request",
            request_id: "interrupt",
            request: { subtype: "interrupt" }
        });
    }

    function buildPermissionResponse(permissionRequest, allow, updatedInput): string {
        // A denial still comes back as an error tool_result; recording the decision here
        // stops that result from relabelling the fence as failed
        // A question is spent once answered, never run: leaving it "running" would have the
        // turn's own cleanup rewrite the fence the service just filled with the answers
        const tool = pendingTools[permissionRequest.toolUseId];
        if (tool) {
            if (!allow) tool.state = "denied";
            else if (tool.name === "AskUserQuestion") tool.state = "answered";
            else {
                tool.state = "running";
                tool.startedAt = Date.now();
            }
        }
        return JSON.stringify({
            type: "control_response",
            response: {
                subtype: "success",
                request_id: permissionRequest.requestId,
                response: allow
                    ? { behavior: "allow", updatedInput: updatedInput ?? permissionRequest.input }
                    : { behavior: "deny", message: "User rejected this command" }
            }
        });
    }

    // Encodes the AskUserQuestion answer contract for updatedInput: {questions, answers}
    // keyed by question text, multiSelect labels joined with ", ", skipped questions
    // (no selection) omitted
    function buildQuestionAnswers(questions, selections): var {
        const answers = {};
        for (const q of questions) {
            const answer = (selections[q.question] ?? []).join(", ");
            if (answer.length > 0) answers[q.question] = answer;
        }
        return { questions: questions, answers: answers };
    }

    function finalizeScriptContent(scriptContent: string): string {
        const request = pendingRequest;
        // stdio permission prompts let the shell approve/deny gated tool calls over stdin
        let command = "claude -p --input-format stream-json --output-format stream-json"
            + " --include-partial-messages --verbose --permission-prompt-tool stdio";
        if (request.model.model.length > 0) {
            command += ` --model '${CF.StringUtils.shellSingleQuoteEscape(request.model.model)}'`;
        }
        if (request.sessionId.length > 0) {
            command += ` --resume '${CF.StringUtils.shellSingleQuoteEscape(request.sessionId)}'`;
        }
        if (request.systemPrompt.length > 0) {
            command += ` --append-system-prompt '${CF.StringUtils.shellSingleQuoteEscape(request.systemPrompt)}'`;
        }
        // exec so the stop button's kill reaches claude itself, not just the wrapping bash
        return "#!/usr/bin/env bash\nexec " + command + "\n";
    }

    function appendContent(message, text) {
        message.content += text;
        message.rawContent += text;
    }

    function registerTool(id, name, message) {
        const tool = {
            name: name,
            inputJson: "",
            // Nothing exists to run or approve yet; the state settles once the input is in
            state: "streaming",
            // This fence is about to be appended, so the fences already there are its ordinal
            ordinal: CF.StringUtils.commandFences(message.content).length,
        };
        pendingTools[id] = tool;
        appendContent(message, `\n\n${fenceText(tool)}\n\n`);
        return tool;
    }

    function fenceText(tool) {
        return `\`\`\`command:${tool.name}:${tool.state}${timingToken(tool)}\n${commandSummary(tool)}${outputSection(tool)}\n\`\`\``;
    }

    // When it started while it runs, how long it took once it is over. Carried in the info
    // string because the delegate is rebuilt on every rewrite, so a clock it started itself
    // would restart with it. Neither token is a state or the tool name, so the fence still
    // parses as before
    function timingToken(tool) {
        if (tool.elapsedSeconds !== undefined) return `:d${tool.elapsedSeconds}`;
        if (tool.startedAt !== undefined) return `:t${tool.startedAt}`;
        return "";
    }

    // Backtick runs in output would close the fence early and shift every later ordinal, so
    // they get an invisible break; a separator of its own would do the same to the split
    function outputSection(tool) {
        if (!(tool.output?.length > 0)) return "";
        const safe = tool.output
            .replace(new RegExp(CF.StringUtils.commandOutputSeparator, "g"), "")
            .replace(/```/g, "``\u200b`");
        return `\n${CF.StringUtils.commandOutputSeparator}\n${safe}`;
    }

    function captureTiming(tool) {
        if (tool.startedAt === undefined) return;
        tool.elapsedSeconds = Math.floor((Date.now() - tool.startedAt) / 1000);
    }

    function captureOutput(tool, block) {
        if (tool.name !== "Bash" && !block.is_error) return;
        const content = block.content;
        const text = Array.isArray(content)
            ? content.filter(part => part.type === "text").map(part => part.text).join("\n")
            : (content ?? "");
        // Kept as the command printed it, blank lines and all; only the length is bounded,
        // and whatever went wrong is at the end, so the head is what a long log loses
        const lines = String(text).split("\n");
        const kept = lines.slice(-maxOutputLines);
        if (kept.length < lines.length) kept.unshift("…");
        tool.output = kept.join("\n");
    }

    // By ordinal rather than by offset: a fence settling earlier in the message shifts
    // every later one, and several tool calls can be in flight at once
    function rewriteFence(message, tool) {
        const render = () => fenceText(tool);
        message.content = CF.StringUtils.editCommandFence(message.content, tool.ordinal, render);
        message.rawContent = CF.StringUtils.editCommandFence(message.rawContent, tool.ordinal, render);
    }

    // Tools that take a command show it as the fence body; the rest show their whole input,
    // so the body stays valid JSON for delegates that parse it back. Never empty: a blank
    // body makes the fence invisible to commandFences and shifts every later ordinal
    function commandSummary(tool) {
        const input = tool.input ?? CF.StringUtils.parsePartialJson(tool.inputJson);
        if (input) tool.lastSummary = input.command ?? JSON.stringify(input);
        return (tool.lastSummary?.length > 0) ? tool.lastSummary : "{}";
    }

    function queuePromotion(id, message) {
        promotionQueue = promotionQueue.concat([{ id: id, due: Date.now() + promotionDelay }]);
        promotionMessage = message;
        if (!promotionTimer.running) promotionTimer.start();
    }

    function parseResponseLine(line, message) {
        try {
            const dataJson = JSON.parse(line);

            if (dataJson.type === "system" && dataJson.subtype === "init") {
                message.cliSessionId = dataJson.session_id ?? "";
                return {};
            }

            // Live chunks; complete "assistant" snapshots are ignored to avoid duplication
            if (dataJson.type === "stream_event") {
                const event = dataJson.event ?? {};
                if (event.type === "content_block_start") {
                    const block = event.content_block ?? {};
                    if (block.type === "thinking") {
                        inThinkingBlock = true;
                        appendContent(message, "\n\n<think>\n");
                    } else if (block.type === "tool_use") {
                        currentToolId = block.id ?? "";
                        registerTool(currentToolId, block.name ?? "", message);
                    }
                } else if (event.type === "content_block_delta") {
                    const delta = event.delta ?? {};
                    if (delta.type === "text_delta") {
                        appendContent(message, delta.text ?? "");
                    } else if (delta.type === "thinking_delta") {
                        appendContent(message, delta.thinking ?? "");
                    } else if (delta.type === "input_json_delta") {
                        const tool = pendingTools[currentToolId];
                        if (tool) {
                            tool.inputJson += delta.partial_json ?? "";
                            rewriteFence(message, tool);
                        }
                    }
                } else if (event.type === "content_block_stop") {
                    if (inThinkingBlock) {
                        inThinkingBlock = false;
                        appendContent(message, "\n</think>\n\n");
                    } else {
                        const tool = pendingTools[currentToolId];
                        if (tool) {
                            if (tool.input === undefined) {
                                try { tool.input = JSON.parse(tool.inputJson); } catch (e) {}
                            }
                            rewriteFence(message, tool);
                            queuePromotion(currentToolId, message);
                        }
                        currentToolId = "";
                    }
                }
                return {};
            }

            // Tool results ride on "user" lines and settle the fence's state
            if (dataJson.type === "user") {
                const blocks = dataJson.message?.content;
                if (Array.isArray(blocks)) {
                    for (const block of blocks) {
                        if (block.type !== "tool_result") continue;
                        const tool = pendingTools[block.tool_use_id];
                        // A decision the user already made stands: a denial's error result must not
                        // relabel the fence, and AskUserQuestion keeps its own :answered end state.
                        // Anything else settles here, including tools that needed no approval and
                        // so never left :streaming
                        if (!tool || ["denied", "answered"].includes(tool.state)
                            || tool.name === "AskUserQuestion") continue;
                        tool.state = block.is_error ? "failed" : "done";
                        captureTiming(tool);
                        captureOutput(tool, block);
                        rewriteFence(message, tool);
                    }
                }
                return {};
            }

            if (dataJson.type === "control_request") {
                const request = dataJson.request ?? {};
                if (request.subtype === "can_use_tool") {
                    let tool = pendingTools[request.tool_use_id];
                    if (!tool) tool = registerTool(request.tool_use_id, request.tool_name ?? "", message);
                    // Nothing runs until the user decides; tools that need no approval never
                    // reach here and go straight from streaming to their result
                    tool.state = "pending";
                    // The request can beat the block's stop event; its input is authoritative
                    tool.input = request.input ?? {};
                    rewriteFence(message, tool);
                    message.pendingCommandIndex = tool.ordinal;
                    message.functionName = request.tool_name ?? "";
                    message.functionPending = true;
                    return { permissionRequest: {
                        requestId: dataJson.request_id,
                        toolUseId: request.tool_use_id ?? "",
                        input: request.input ?? {}
                    } };
                }
                return {};
            }

            if (dataJson.type === "result") {
                // A self-requested interrupt also reports is_error (with an internal
                // diagnostic), but the session stays valid and resumable
                if (dataJson.is_error && !interruptRequested) {
                    // error_during_execution results carry errors[] instead of result
                    const errorText = dataJson.result ?? dataJson.errors?.join("\n") ?? "Unknown error";
                    appendContent(message, `**Error**: ${errorText}`);
                    // A failed session (e.g. an expired --resume target) must not be resumed
                    // again: dropping the ids makes the next request start fresh
                    message.cliSessionId = "";
                    pendingRequest?.messages?.forEach(m => { m.cliSessionId = "" });
                }
                const usage = dataJson.usage ?? {};
                const input = (usage.input_tokens ?? 0)
                    + (usage.cache_read_input_tokens ?? 0)
                    + (usage.cache_creation_input_tokens ?? 0);
                const output = usage.output_tokens ?? 0;
                return {
                    finished: true,
                    tokenUsage: { input: input, output: output, total: input + output }
                };
            }
        } catch (e) {
            // Non-JSON output is shown as-is
            appendContent(message, line);
        }
        return {};
    }

    function onRequestFinished(message: AiMessageData): var {
        // An interrupt can land mid-thinking; the dangling tag would swallow the rest of the message
        if (inThinkingBlock) {
            inThinkingBlock = false;
            appendContent(message, "\n</think>\n\n");
        }
        // An interrupt can also land mid-input or mid-execution, leaving a fence unsettled for
        // good. Stopping the turn refuses one that never started; a killed run reads as failed
        promotionTimer.stop();
        promotionQueue = [];
        const leftover = interruptRequested ? "denied" : "failed";
        Object.keys(pendingTools).forEach(id => {
            const tool = pendingTools[id];
            if (!["streaming", "running"].includes(tool.state)) return;
            tool.state = tool.state === "running" ? "failed" : leftover;
            captureTiming(tool);
            rewriteFence(message, tool);
        });
        return {};
    }

    function reset() {
        pendingRequest = null;
        inThinkingBlock = false;
        currentToolId = "";
        pendingTools = ({});
        interruptRequested = false;
        promotionTimer.stop();
        promotionQueue = [];
        promotionMessage = null;
    }
}

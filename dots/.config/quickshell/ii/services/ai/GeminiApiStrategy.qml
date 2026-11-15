import QtQuick
import qs.modules.common.functions as CF

ApiStrategy {
    readonly property string apiKeyEnvVarName: "API_KEY"
    readonly property string fileListVarName: "UPLOADED_FILES_JSON"
    readonly property string fileListSubstitutionString: "{{ uploadedFilesJson }}"
    property string buffer: ""
    
    function buildEndpoint(model: AiModel): string {
        const result = model.endpoint + `?key=\$\{${root.apiKeyEnvVarName}\}`
        // console.log("[AI] Endpoint: " + result);
        return result;
    }

    function attachmentPart(attachment) {
        return {
            "file_data": {
                "mime_type": attachment.fileMimeType,
                "file_uri": attachment.fileUri
            }
        };
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, pendingFiles: var) {
        let contents = messages.map(message => {
            // console.log("[AI] Building request data for message:", JSON.stringify(message, null, 2));
            const geminiApiRoleName = (message.role === "assistant") ? "model" : message.role;
            const usingSearch = tools[0]?.google_search !== undefined
            if (!usingSearch && message.functionCall != undefined && message.functionName.length > 0) {
                return {
                    "role": geminiApiRoleName,
                    "parts": [{
                        functionCall: {
                            "name": message.functionName,
                        }
                    }]
                }
            }
            if (!usingSearch && message.functionResponse != undefined && message.functionName.length > 0) {
                return {
                    "role": geminiApiRoleName,
                    "parts": [{ 
                        functionResponse: {
                            "name": message.functionName,
                            "response": { "content": message.functionResponse }
                        }
                    }]
                }
            }
            const messageAttachments = (message.attachments ?? [])
                .filter(attachment => attachment.fileUri && attachment.fileUri.length > 0)
                .map(attachment => attachmentPart(attachment));
            return {
                "role": geminiApiRoleName,
                "parts": [
                    ...messageAttachments,
                    { text: message.rawContent },
                    ...(messageAttachments.length === 0 && message.fileUri && message.fileUri.length > 0 ? [attachmentPart(message)] : [])
                ]
            }
        })
        if (pendingFiles && pendingFiles.length > 0) {
            contents[contents.length - 1].parts = [
                ...contents[contents.length - 1].parts,
                fileListSubstitutionString,
            ];
        }
        let baseData = {
            "contents": contents,
            "tools": tools,
            "system_instruction": {
                "parts": [{ text: systemPrompt }]
            },
            "generationConfig": {
                "temperature": temperature,
            },
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return "";
    }

    function parseResponseLine(line, message) {
        if (line.startsWith("[")) {
            buffer += line.slice(1).trim();
        } else if (line === "]") {
            buffer += line.slice(0, -1).trim();
            return parseBuffer(message);
        } else if (line.startsWith(",")) {
            return parseBuffer(message);
        } else {
            buffer += line.trim();
        }
        return {};
    }

    function parseBuffer(message) {
        let finished = false;
        try {
            if (buffer.length === 0) return {};
            const dataJson = JSON.parse(buffer);

            if (dataJson.uploadedFile) {
                const targetMessage = root.attachmentTargetMessage || message;
                if (!targetMessage) return {};

                const attachments = [...(targetMessage.attachments ?? [])];
                const attachmentIndex = attachments.findIndex(attachment => !attachment.fileUri || attachment.fileUri.length === 0);
                if (attachmentIndex !== -1) {
                    attachments[attachmentIndex] = Object.assign({}, attachments[attachmentIndex], {
                        "fileUri": dataJson.uploadedFile.uri,
                        "fileMimeType": dataJson.uploadedFile.mimeType,
                    });
                    targetMessage.attachments = attachments;
                    if (attachmentIndex === 0) {
                        targetMessage.fileUri = dataJson.uploadedFile.uri;
                        targetMessage.fileMimeType = dataJson.uploadedFile.mimeType;
                    }
                } else {
                    targetMessage.fileUri = dataJson.uploadedFile.uri;
                    targetMessage.fileMimeType = dataJson.uploadedFile.mimeType;
                }
                targetMessage.localFilePath = targetMessage.attachments?.[0]?.localFilePath ?? targetMessage.localFilePath;
                return ({})
            }

            if (dataJson.error) {
                const errorMsg = `**Error ${dataJson.error.code}**: ${dataJson.error.message}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            if (!dataJson.candidates) return {};
            
            if (dataJson.candidates[0]?.finishReason) {
                finished = true;
            }
            
            if (dataJson.candidates[0]?.content?.parts[0]?.functionCall) {
                const functionCall = dataJson.candidates[0]?.content?.parts[0]?.functionCall;
                message.functionName = functionCall.name;
                message.functionCall = functionCall.name;
                const newContent = `\n\n[[ Function: ${functionCall.name}(${JSON.stringify(functionCall.args, null, 2)}) ]]\n`
                message.rawContent += newContent;
                message.content += newContent;
                return { functionCall: { name: functionCall.name, args: functionCall.args }, finished: finished };
            }

            const responseContent = dataJson.candidates[0]?.content?.parts[0]?.text
            message.rawContent += responseContent;
            message.content += responseContent;
            
            const annotationSources = dataJson.candidates[0]?.groundingMetadata?.groundingChunks?.map(chunk => {
                return {
                    "type": "url_citation",
                    "text": chunk?.web?.title,
                    "url": chunk?.web?.uri,
                }
            }) ?? [];

            const annotations = dataJson.candidates[0]?.groundingMetadata?.groundingSupports?.map(citation => {
                return {
                    "type": "url_citation",
                    "start_index": citation.segment?.startIndex,
                    "end_index": citation.segment?.endIndex,
                    "text": citation?.segment.text,
                    "url": annotationSources[citation.groundingChunkIndices[0]]?.url,
                    "sources": citation.groundingChunkIndices
                }
            });
            message.annotationSources = annotationSources;
            message.annotations = annotations;
            message.searchQueries = dataJson.candidates[0]?.groundingMetadata?.webSearchQueries ?? [];

            if (dataJson.usageMetadata) {
                return {
                    tokenUsage: {
                        input: dataJson.usageMetadata.promptTokenCount ?? -1,
                        output: dataJson.usageMetadata.candidatesTokenCount ?? -1,
                        total: dataJson.usageMetadata.totalTokenCount ?? -1
                    },
                    finished: finished
                };
            }
            
        } catch (e) {
            console.log("[AI] Gemini: Could not parse buffer: ", e);
            message.rawContent += buffer;
            message.content += buffer;
        } finally {
            buffer = "";
        }
        return { finished: finished };
    }

    function onRequestFinished(message) {
        return parseBuffer(message);
    }
    
    function reset() {
        buffer = "";
    }

    function buildScriptFileSetup(pendingFiles: var) {
        if (!pendingFiles || pendingFiles.length === 0) return "";

        let content = ""
        content += `${fileListVarName}=""\n`;
        content += 'mkdir -p "/tmp/quickshell/ai"\n';

        pendingFiles.forEach((filePath, index) => {
            const trimmedFilePath = CF.FileUtils.trimFileProtocol(filePath);
            const imagePathVarName = `IMAGE_PATH_${index}`;
            const fileMimeTypeVarName = `MIME_TYPE_${index}`;
            const fileUriVarName = `FILE_URI_${index}`;
            const numBytesVarName = `NUM_BYTES_${index}`;
            const tmpHeaderVarName = `TMP_HEADER_FILE_${index}`;
            const tmpFileInfoVarName = `TMP_FILE_INFO_${index}`;
            const uploadUrlVarName = `UPLOAD_URL_${index}`;
            const uploadErrorVarName = `UPLOAD_ERROR_${index}`;

            content += `${imagePathVarName}='${CF.StringUtils.shellSingleQuoteEscape(trimmedFilePath)}'\n`;
            content += `if [ ! -f "$${imagePathVarName}" ] || [ ! -s "$${imagePathVarName}" ]; then printf '{"error": {"code": 400, "message": "Attached file is missing or unreadable: %s"}}\n' "$${imagePathVarName}"; exit 1; fi\n`;
            content += `${fileMimeTypeVarName}=$(file -b --mime-type "$${imagePathVarName}")\n`;
            content += `${numBytesVarName}=$(wc -c < "$${imagePathVarName}")\n`;
            content += `${tmpHeaderVarName}="/tmp/quickshell/ai/upload-header-${index}.tmp"\n`;
            content += `${tmpFileInfoVarName}="/tmp/quickshell/ai/file-info-${index}.json.tmp"\n`;
            content += 'curl "https://generativelanguage.googleapis.com/upload/v1beta/files"'
                + ` -H "x-goog-api-key: \$${apiKeyEnvVarName}"`
                + ` -D "$${tmpHeaderVarName}"`
                + ' -H "X-Goog-Upload-Protocol: resumable"'
                + ' -H "X-Goog-Upload-Command: start"'
                + ` -H "X-Goog-Upload-Header-Content-Length: \$\{${numBytesVarName}\}"`
                + ` -H "X-Goog-Upload-Header-Content-Type: \$\{${fileMimeTypeVarName}\}"`
                + ' -H "Content-Type: application/json"'
                + ` -d '{"file": {"display_name": "Attachment ${index + 1}"}}' 2> /dev/null`
                + '\n';
            content += `${uploadUrlVarName}=$(grep -i "x-goog-upload-url: " "$${tmpHeaderVarName}" | cut -d" " -f2 | tr -d "\r")\n`;
            content += `rm "$${tmpHeaderVarName}"\n`;
            content += `if [ -z "$${uploadUrlVarName}" ]; then printf '{"error": {"code": 400, "message": "Failed to start Gemini file upload for %s"}}\n' "$${imagePathVarName}"; exit 1; fi\n`;
            content += 'curl "$'
                + `{${uploadUrlVarName}}"`
                + ` -H "x-goog-api-key: \$${apiKeyEnvVarName}"`
                + ` -H "Content-Length: \$\{${numBytesVarName}\}"`
                + ' -H "X-Goog-Upload-Offset: 0"'
                + ' -H "X-Goog-Upload-Command: upload, finalize"'
                + ` --data-binary "@$${imagePathVarName}" 2> /dev/null > "$${tmpFileInfoVarName}"`
                + '\n';
            content += `${fileUriVarName}=$(jq -r '.file.uri // empty' "$${tmpFileInfoVarName}")\n`;
            content += `${uploadErrorVarName}=$(jq -r '.error.message // empty' "$${tmpFileInfoVarName}")\n`;
            content += `if [ -z "$${fileUriVarName}" ]; then [ -n "$${uploadErrorVarName}" ] || ${uploadErrorVarName}='No file URI returned from Gemini file upload'; printf '{"error": {"code": 400, "message": "Gemini file upload failed for %s: %s"}}\n' "$${imagePathVarName}" "$${uploadErrorVarName}"; exit 1; fi\n`;
            content += `${fileListVarName}+=$(jq -cn --arg uri "$${fileUriVarName}" --arg mimeType "$${fileMimeTypeVarName}" '{"file_data": {"mime_type": $mimeType, "file_uri": $uri}}')\n`;
            content += `${fileListVarName}+=','\n`;
            content += `printf '{"uploadedFile": {"uri": "%s", "mimeType": "%s"}}\n,\n' "$${fileUriVarName}" "$${fileMimeTypeVarName}"\n`;
        });

        return content
    }

    function finalizeScriptContent(scriptContent: string): string {
        const uploadedPartsReference = "'\"${" + fileListVarName + "%,}\"'";
        return scriptContent.replace(`"${fileListSubstitutionString}"`, uploadedPartsReference);
    }
}

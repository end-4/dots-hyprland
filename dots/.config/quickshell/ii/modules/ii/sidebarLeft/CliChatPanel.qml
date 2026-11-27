pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import "./aiChat"

Item {
    id: root
    required property string backend // "claude" | "codex"

    property string sessionId: ""
    property bool busy: false
    property bool modelPickerOpen: false
    property bool cliInstalled: true
    property bool cliLoggedIn: true
    property bool installing: false
    property bool needsPassword: false
    property real installProgress: 0.0
    property string installStatus: ""
    property string selectedModel: ""
    property string selectedEffort: "medium"
    property var modelCatalog: []
    property var cliCommands: []
    property var suggestionList: []
    property var pendingFilePaths: []

    function normalizePath(rawPath: string) {
        let p = (rawPath ?? "").trim();
        if (p.startsWith("file://"))
            p = FileUtils.trimFileProtocol(p);
        try { p = decodeURIComponent(p); } catch (e) {}
        return p;
    }

    function attachFiles(rawList) {
        const next = root.pendingFilePaths.slice();
        for (let i = 0; i < rawList.length; i++) {
            const p = root.normalizePath(String(rawList[i] ?? ""));
            if (p && next.indexOf(p) < 0)
                next.push(p);
        }
        root.pendingFilePaths = next;
    }

    function attachFile(rawPath: string) {
        root.attachFiles([rawPath]);
    }

    function removeAttachedFile(path: string) {
        root.pendingFilePaths = root.pendingFilePaths.filter(p => p !== path);
    }

    readonly property string metaScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/fetch-cli-meta.py`)

    function startInstall() {
        if (root.installing)
            return;
        root.installing = true;
        root.needsPassword = false;
        root.installProgress = 0.10;
        root.installStatus = Translation.tr("Preparing installation…");
        const pkg = root.backend === "claude" ? "claude-code" : "openai-codex";
        const npmPkg = root.backend === "claude" ? "@anthropic-ai/claude-code" : "@openai/codex";
        installProc.command = [
            "bash", "-c",
            `if command -v pacman >/dev/null 2>&1 && pacman -Si ${pkg} >/dev/null 2>&1; then ` +
            `  sudo -S -p $'SUDO_PWD_PROMPT\\n' pacman -S --needed --noconfirm ${pkg}; ` +
            `elif command -v paru >/dev/null 2>&1; then ` +
            `  echo "SUDO_PWD_PROMPT" >&2; paru --sudoflags="-S" -S --needed --noconfirm ${pkg}; ` +
            `elif command -v npm >/dev/null 2>&1; then ` +
            `  npm install -g --prefix "$HOME/.local" ${npmPkg}; ` +
            `else echo "ERR: pacman/paru/npm not found" >&2; exit 1; fi`
        ];
        installProc.running = true;
    }

    function submitInstallPassword(pwd: string) {
        if (!installProc.running || !pwd)
            return;
        root.needsPassword = false;
        root.installStatus = Translation.tr("Authenticating & installing…");
        installProc.write(pwd + "\n");
    }

    Timer {
        id: installProgressTimer
        interval: 900
        repeat: true
        running: root.installing && !root.needsPassword
        onTriggered: {
            if (root.installProgress < 0.88)
                root.installProgress = Math.min(0.88, root.installProgress + 0.04);
        }
    }

    Process {
        id: installProc
        stdout: SplitParser {
            onRead: data => {
                const line = (data ?? "").trim();
                if (!line) return;
                root.installStatus = line;
                if (line.includes("added") || line.includes("Installing"))
                    root.installProgress = Math.max(root.installProgress, 0.75);
                else
                    root.installProgress = Math.min(0.92, root.installProgress + 0.08);
            }
        }
        stderr: SplitParser {
            onRead: data => {
                const line = (data ?? "").trim();
                if (!line) return;
                if (/SUDO_PWD_PROMPT|password|parola|sudo/i.test(line)) {
                    root.needsPassword = true;
                    root.installStatus = Translation.tr("Administrator password required");
                    Qt.callLater(() => pwdField.forceActiveFocus());
                } else {
                    root.installStatus = line;
                }
            }
        }
        onExited: (code, status) => {
            root.installing = false;
            root.needsPassword = false;
            if (code === 0) {
                root.installProgress = 1.0;
                root.installStatus = Translation.tr("Installed!");
                root.refreshMeta();
            } else {
                root.installProgress = 0.0;
                root.installStatus = Translation.tr("Installation failed (exit %1)").arg(code);
            }
        }
    }

    function refreshMeta() {
        metaProc.running = false;
        metaProc.running = true;
    }

    Component.onCompleted: root.refreshMeta()

    Process {
        id: metaProc
        command: ["python3", root.metaScript, root.backend]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.cliInstalled = !!data.installed;
                    root.cliLoggedIn = data.loggedIn !== undefined ? !!data.loggedIn : true;
                    root.modelCatalog = data.models ?? [];
                    root.cliCommands = data.commands ?? [];
                    if (!root.selectedModel && data.defaultModel)
                        root.selectedModel = data.defaultModel;
                } catch (e) {}
            }
        }
    }

    function currentModelObj() {
        for (let i = 0; i < modelCatalog.length; i++) {
            if (modelCatalog[i].id === root.selectedModel)
                return modelCatalog[i];
        }
        return modelCatalog[0] ?? { id: root.selectedModel, name: root.selectedModel || root.backend, efforts: [] };
    }

    function currentModelLabel(): string {
        const m = currentModelObj();
        if (m.efforts && m.efforts.length > 0)
            return m.name + " (" + root.selectedEffort + ")";
        return m.name;
    }

    function appendMessage(role: string, text: string) {
        msgModel.append({ role: role, content: text });
        Qt.callLater(() => msgList.positionViewAtEnd());
    }

    function updateLastAssistant(text: string, replace: bool) {
        if (msgModel.count === 0)
            return;
        const idx = msgModel.count - 1;
        const cur = msgModel.get(idx).content;
        msgModel.setProperty(idx, "content", replace ? text : (cur + text));
        Qt.callLater(() => msgList.positionViewAtEnd());
    }

    Process {
        id: loginProc
        onExited: root.refreshMeta()
    }

    function openLogin() {
        const cmd = root.backend === "claude" ? "claude auth login" : "codex login";
        loginProc.command = ["bash", "-c", `${Config.options.apps.terminal} -e bash -c '${cmd}; echo; read -p "Press Enter to close..."'`];
        loginProc.running = false;
        loginProc.running = true;
    }

    function clearChat() {
        root.sessionId = "";
        msgModel.clear();
    }

    function stopPrompt() {
        if (!root.busy && !runner.running)
            return;
        runner.running = false;
        root.busy = false;
        if (msgModel.count > 0) {
            const idx = msgModel.count - 1;
            if (msgModel.get(idx).role === "assistant" && msgModel.get(idx).content.trim() === "")
                root.updateLastAssistant("[Stopped]", true);
        }
    }

    function sendPrompt(rawText: string) {
        const text = rawText.trim();
        if ((!text && root.pendingFilePaths.length === 0) || root.busy)
            return;

        if (text.startsWith("/")) {
            const cmd = text.split(/\s+/)[0].toLowerCase();
            if (cmd === "/model" || cmd === "/effort") {
                root.modelPickerOpen = true;
                return;
            }
            if (cmd === "/login") {
                root.openLogin();
                return;
            }
            if (cmd === "/clear") {
                root.clearChat();
                return;
            }
            if (cmd === "/attach") {
                root.attachFile(text.slice(7).trim());
                return;
            }
        }

        const attached = root.pendingFilePaths.slice();
        root.pendingFilePaths = [];
        const attachedHeader = attached.map(p => `[Attached file: ${p}]`).join("\n");
        const promptText = attached.length > 0
            ? (text !== "" ? `${attachedHeader}\n${text}` : `${attachedHeader}\nPlease inspect these files.`)
            : text;

        root.appendMessage("user", promptText);
        root.appendMessage("assistant", "");
        root.busy = true;

        const m = currentModelObj();
        if (root.backend === "claude") {
            const args = [
                "claude", "-p", promptText,
                "--output-format", "stream-json",
                "--verbose",
                "--include-partial-messages",
                "--model", m.id
            ];
            if (m.efforts && m.efforts.length > 0) {
                args.push("--effort", root.selectedEffort);
            }
            if (root.sessionId !== "") {
                args.push("--resume", root.sessionId);
            }
            runner.command = args;
        } else {
            const args = ["codex", "exec"];
            if (root.sessionId !== "") {
                args.push("resume", root.sessionId);
            }
            args.push("--json", "-m", m.id);
            if (m.efforts && m.efforts.length > 0) {
                args.push("-c", `model_reasoning_effort="${root.selectedEffort}"`);
            }
            for (let i = 0; i < attached.length; i++) {
                if (/\.(png|jpe?g|webp|gif)$/i.test(attached[i])) {
                    args.push("-i", attached[i]);
                }
            }
            args.push("--skip-git-repo-check", promptText);
            runner.command = ["bash", "-c", 'exec "$@" </dev/null', "_", ...args];
        }
        runner.running = true;
    }

    ListModel {
        id: msgModel
    }

    Process {
        id: runner
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim().startsWith("{"))
                    return;
                try {
                    const ev = JSON.parse(data);
                    if (root.backend === "claude") {
                        if (ev.session_id)
                            root.sessionId = ev.session_id;
                        if (ev.type === "stream_event" && ev.event?.delta?.type === "text_delta" && ev.event.delta.text) {
                            root.updateLastAssistant(ev.event.delta.text, false);
                        } else if (ev.type === "assistant" && ev.message?.content) {
                            const parts = ev.message.content.filter(c => c.type === "text").map(c => c.text).join("");
                            if (parts)
                                root.updateLastAssistant(parts, true);
                        } else if (ev.type === "result" && ev.result) {
                            root.updateLastAssistant(ev.result, true);
                        }
                    } else {
                        if (ev.thread_id)
                            root.sessionId = ev.thread_id;
                        if (ev.type === "item.completed" && ev.item?.type === "agent_message" && ev.item.text) {
                            root.updateLastAssistant(ev.item.text, true);
                        } else if (ev.type === "agent_message" && ev.text) {
                            root.updateLastAssistant(ev.text, false);
                        }
                    }
                } catch (e) {}
            }
        }
        property string errBuf: ""
        stderr: SplitParser {
            onRead: data => {
                runner.errBuf += data + "\n";
            }
        }
        onExited: (code, status) => {
            root.busy = false;
            if (msgModel.count > 0) {
                const idx = msgModel.count - 1;
                if (msgModel.get(idx).content.trim() === "" && code !== 0) {
                    const err = runner.errBuf.trim();
                    root.updateLastAssistant(
                        err !== "" ? err : (
                            (root.backend === "codex" ? "codex" : "claude") + ` CLI error (exit ${code}). Run /login or check installation.`
                        ),
                        true
                    );
                    if (/login|auth|unauthorized|401|credential|token/i.test(err)) {
                        root.refreshMeta();
                    }
                }
            }
            runner.errBuf = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // On-demand CLI installer card when claude/codex is not installed
        Item {
            visible: !root.cliInstalled
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, 340)
                implicitHeight: instCol.implicitHeight + 32
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant

                ColumnLayout {
                    id: instCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16
                    spacing: 12

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.installing ? "downloading" : "terminal"
                        iconSize: 36
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                        text: root.backend === "claude"
                            ? Translation.tr("Claude CLI is not installed")
                            : Translation.tr("Codex CLI is not installed")
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: root.installStatus || Translation.tr("Would you like to install it now?")
                    }

                    // Animated percentage progress bar
                    ColumnLayout {
                        visible: root.installing || root.installProgress > 0
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colSurfaceContainerHigh
                            clip: true

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.installProgress
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colPrimary
                                Behavior on width {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            font.pixelSize: Appearance.font.pixelSize.smaller - 1
                            font.family: Appearance.font.family.monospace
                            color: Appearance.colors.colPrimary
                            text: Math.round(root.installProgress * 100) + "%"
                        }
                    }

                    // Inline sudo password prompt when needed
                    RowLayout {
                        visible: root.needsPassword
                        Layout.fillWidth: true
                        spacing: 6

                        TextField {
                            id: pwdField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: Translation.tr("Enter password")
                            onAccepted: {
                                root.submitInstallPassword(text);
                                text = "";
                            }
                        }
                        RippleButton {
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimary
                            onClicked: {
                                root.submitInstallPassword(pwdField.text);
                                pwdField.text = "";
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: 18
                                color: Appearance.m3colors.m3onPrimary
                            }
                        }
                    }

                    RippleButton {
                        visible: !root.installing
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: instBtnText.implicitWidth + 32
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        onClicked: root.startInstall()
                        contentItem: StyledText {
                            id: instBtnText
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onPrimary
                            text: Translation.tr("Install")
                        }
                    }
                }
            }
        }

        // Auth prompt banner when CLI is installed and not logged in (or login in progress)
        Rectangle {
            visible: root.cliInstalled && (!root.cliLoggedIn || loginProc.running)
            Layout.fillWidth: true
            implicitHeight: authCol.implicitHeight + 16
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            ColumnLayout {
                id: authCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    id: authRow
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialLoadingIndicator {
                        visible: loginProc.running
                        implicitSize: 18
                    }
                    MaterialSymbol {
                        visible: !loginProc.running
                        text: "passkey"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurface
                        elide: Text.ElideRight
                        text: loginProc.running
                            ? Translation.tr("Signing in to %1...").arg(root.backend === "codex" ? "Codex" : "Claude")
                            : Translation.tr("Sign in required to use %1").arg(root.backend === "codex" ? "Codex" : "Claude")
                    }
                    RippleButton {
                        implicitWidth: loginBtnTxt.implicitWidth + 20
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        enabled: !loginProc.running
                        colBackground: Appearance.colors.colPrimary
                        onClicked: root.openLogin()
                        contentItem: StyledText {
                            id: loginBtnTxt
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onPrimary
                            text: loginProc.running ? Translation.tr("Waiting...") : Translation.tr("Sign in")
                        }
                    }
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                        onClicked: root.refreshMeta()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 16
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // Clean spinner + status in RowLayout above (no extra bar needed)
            }
        }

        Item {
            visible: root.cliInstalled
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                visible: root.modelPickerOpen
                z: 5
                onPressed: mouse => {
                    root.modelPickerOpen = false;
                    mouse.accepted = false;
                }
            }

            ListView {
                id: msgList
                anchors.fill: parent
                clip: true
                spacing: 6
                model: msgModel

                delegate: Rectangle {
                    id: msgCard
                    required property string role
                    required property string content
                    width: msgList.width
                    implicitHeight: msgCol.implicitHeight + 10
                    radius: Appearance.rounding.small
                    color: role === "user" ? ColorUtils.transparentize(Appearance.colors.colLayer2, 0.45) : "transparent"

                    ColumnLayout {
                        id: msgCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 5
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.family: Appearance.font.family.monospace
                                font.weight: Font.DemiBold
                                color: msgCard.role === "user" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                text: msgCard.role === "user" ? ">" : ("✦ " + root.currentModelLabel())
                            }
                            Item { Layout.fillWidth: true }
                            RippleButton {
                                implicitWidth: 24
                                implicitHeight: 24
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                                onClicked: Quickshell.clipboardText = msgCard.content
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "content_copy"
                                    iconSize: 14
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            text: msgCard.content || (msgCard.role === "assistant" && root.busy ? "…" : "")
                        }
                    }
                }
            }
        }

        // Inline Model & Effort picker
        Rectangle {
            visible: root.modelPickerOpen
            Layout.fillWidth: true
            implicitHeight: Math.min(280, pickerCol.implicitHeight + 14)
            clip: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            ColumnLayout {
                id: pickerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 4

                StyledText {
                    Layout.leftMargin: 6
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    text: root.backend === "claude" ? "Claude Models" : "Codex Models"
                }

                ListView {
                    id: modelListView
                    Layout.fillWidth: true
                    implicitHeight: Math.min(220, contentHeight)
                    clip: true
                    spacing: 3
                    model: root.modelCatalog
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: root.selectedModel === modelData.id
                        readonly property bool hasEfforts: (modelData.efforts?.length ?? 0) > 1
                        width: modelListView.width
                        implicitHeight: mCol.implicitHeight + 6
                        radius: Appearance.rounding.small
                        color: selected ? Appearance.colors.colPrimaryContainer : "transparent"

                        ColumnLayout {
                            id: mCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            spacing: 4

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: selected ? "transparent" : Appearance.colors.colSurfaceContainerHigh
                                onClicked: {
                                    root.selectedModel = modelData.id;
                                    if (hasEfforts && modelData.efforts.indexOf(root.selectedEffort) < 0)
                                        root.selectedEffort = modelData.efforts[0];
                                    if (!hasEfforts)
                                        root.modelPickerOpen = false;
                                }
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    StyledText {
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                                        text: modelData.name
                                    }
                                    MaterialSymbol {
                                        visible: selected
                                        text: "check"
                                        iconSize: 16
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }

                            ColumnLayout {
                                visible: selected && hasEfforts
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 2

                                Slider {
                                    Layout.fillWidth: true
                                    implicitHeight: 22
                                    from: 0
                                    to: Math.max(1, (modelData.efforts?.length ?? 1) - 1)
                                    stepSize: 1
                                    snapMode: Slider.SnapAlways
                                    value: Math.max(0, modelData.efforts.indexOf(root.selectedEffort))
                                    onMoved: {
                                        const eff = modelData.efforts[Math.round(value)];
                                        if (eff)
                                            root.selectedEffort = eff;
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: modelData.efforts
                                        delegate: MouseArea {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            implicitHeight: effLbl.implicitHeight
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEffort = modelData
                                            StyledText {
                                                id: effLbl
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                font.pixelSize: Appearance.font.pixelSize.smaller - 1
                                                color: root.selectedEffort === modelData ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimaryContainer
                                                text: modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Shared scrollable / command list
        CliSlashList {
            id: cliSuggestions
            Layout.fillWidth: true
            model: inputField.text.startsWith("/") ? root.suggestionList : []
            onItemAccepted: item => {
                inputField.clear();
                root.sendPrompt(item.name);
            }
        }

        // Input box
        Rectangle {
            visible: root.cliInstalled
            Layout.fillWidth: true
            implicitHeight: Math.max(66, inputCol.implicitHeight + 10)
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            ColumnLayout {
                id: inputCol
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                ColumnLayout {
                    visible: root.pendingFilePaths.length > 0
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: root.pendingFilePaths
                        delegate: AttachedFileIndicator {
                            required property string modelData
                            Layout.fillWidth: true
                            filePath: modelData
                            onRemove: root.removeAttachedFile(modelData)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledTextArea {
                        id: inputField
                        Layout.fillWidth: true
                        wrapMode: TextArea.Wrap
                        placeholderText: (root?.backend ?? "") === "claude"
                            ? Translation.tr("Message Claude... \"/\" for commands")
                            : Translation.tr("Message Codex... \"/\" for commands")
                        onActiveFocusChanged: if (activeFocus) root.modelPickerOpen = false
                        onTextChanged: {
                            if (text.startsWith("/")) {
                                const q = text.toLowerCase();
                                cliSuggestions.selectedIndex = 0;
                                root.suggestionList = root.cliCommands.filter(c => c.name.startsWith(q));
                            } else {
                                root.suggestionList = [];
                            }
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up && cliSuggestions.visible) {
                                cliSuggestions.moveUp();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && cliSuggestions.visible) {
                                cliSuggestions.moveDown();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                if (root.modelPickerOpen) {
                                    root.modelPickerOpen = false;
                                    event.accepted = true;
                                } else if (cliSuggestions.visible) {
                                    inputField.clear();
                                    event.accepted = true;
                                }
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && root.busy && inputField.selectedText.length === 0) {
                                root.stopPrompt();
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return) && !(event.modifiers & Qt.ShiftModifier)) {
                                if (cliSuggestions.visible) {
                                    const sel = cliSuggestions.currentItem();
                                    if (sel) {
                                        inputField.clear();
                                        root.sendPrompt(sel.name);
                                    }
                                } else {
                                    const t = inputField.text;
                                    inputField.clear();
                                    root.sendPrompt(t);
                                }
                                event.accepted = true;
                            }
                        }
                    }

                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        enabled: root.busy || inputField.text.length > 0 || root.pendingFilePaths.length > 0
                        toggled: enabled
                        onClicked: {
                            if (root.busy) {
                                root.stopPrompt();
                            } else {
                                const t = inputField.text;
                                inputField.clear();
                                root.sendPrompt(t);
                            }
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.busy ? "stop" : "arrow_upward"
                            iconSize: 20
                            color: enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ApiInputBoxIndicator {
                        icon: "api"
                        text: root.currentModelLabel()
                        MouseArea {
                            z: 10
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.modelPickerOpen = !root.modelPickerOpen
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ApiCommandButton {
                        buttonText: "/"
                        onClicked: {
                            inputField.text = "/";
                            inputField.forceActiveFocus();
                        }
                    }
                    ApiCommandButton {
                        buttonText: "/clear"
                        onClicked: root.clearChat()
                    }
                }
            }
        }
    }

    DropArea {
        id: fileDropArea
        anchors.fill: parent
        z: 50
        onEntered: drag => {
            if (drag.hasUrls || drag.hasText)
                drag.accept(Qt.CopyAction);
        }
        onDropped: drop => {
            const list = [];
            if (drop.hasUrls && drop.urls.length > 0) {
                for (let i = 0; i < drop.urls.length; i++)
                    list.push(String(drop.urls[i]));
            } else if (drop.hasText) {
                const lines = drop.text.trim().split(/\r?\n/);
                for (let i = 0; i < lines.length; i++)
                    if (lines[i].trim()) list.push(lines[i].trim());
            }
            if (list.length > 0) {
                root.attachFiles(list);
                drop.accept(Qt.CopyAction);
            }
        }
    }

    Rectangle {
        visible: fileDropArea.containsDrag
        anchors.fill: parent
        anchors.margins: 6
        z: 51
        radius: Appearance.rounding.normal
        color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.72)
        border.width: 2
        border.color: Appearance.colors.colPrimary

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "attach_file"
                iconSize: 32
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnPrimaryContainer
                text: Translation.tr("Drop file to attach")
            }
        }
    }
}

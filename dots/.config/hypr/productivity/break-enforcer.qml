/**
 * Break Enforcer - Mandatory break overlay with productivity questionnaire
 * 
 * Features:
 * - Fullscreen break timer with countdown
 * - 3-question productivity questionnaire after break
 * - Auto-pause media players on break start
 * - Multi-monitor support (prevents duplicate saves)
 * - Stores responses in SQLite database
 * 
 * Environment Variables:
 * - BREAK_DURATION: Duration in seconds (default: 300)
 * - BREAK_TYPE: "eye_care" or "break_reminder" (default: "break_reminder")
 * - TESTING: Set to "1" to allow Alt+F4 to close window
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    /* ---------------- THEME ---------------- */
    property var theme: ({})
    property string themePath: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/colors.json"

    /* ---------------- ENV & INITIALIZATION ---------------- */
    Component.onCompleted: {
        // Load theme
        loadTheme()
        
        // Pause all media players
        pauseMedia()
        
        // Load environment variables
        const envDuration = Quickshell.env("BREAK_DURATION")
        const envType = Quickshell.env("BREAK_TYPE")
        const envTesting = Quickshell.env("TESTING")

        if (envDuration) {
            duration = parseInt(envDuration)
            timeRemaining = duration
        }

        if (envType)
            breakType = envType

        if (envTesting === "1")
            testingMode = true

        timer.start()
    }

    /* ---------------- MEDIA CONTROL ---------------- */
    /**
     * Pause all active media players using playerctl
     * This prevents videos/music from continuing during the break
     */
    function pauseMedia() {
        // Pause all media players using playerctl -a (all players)
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            import QtQuick
            Process {
                running: true
                command: ["playerctl", "-a", "pause"]
            }
        `, root)
    }

    function loadTheme() {
        const file = Qt.createQmlObject('import Quickshell.Io; import QtQuick; FileView { path: "' + themePath + '" }', root)
        try {
            const content = file.text()
            theme = JSON.parse(content)
        } catch (e) {
            console.error("Failed to load theme:", e)
            // Fallback to Catppuccin Mocha colors
            theme = {
                background: "#1e1e2e",
                on_background: "#cdd6f4",
                surface: "#313244",
                on_surface: "#cdd6f4",
                primary: "#89b4fa",
                on_primary: "#1e1e2e",
                secondary_container: "#45475a",
                on_secondary_container: "#cdd6f4",
                outline: "#6c7086",
                error: "#f38ba8"
            }
        }
    }

    /* ---------------- CONFIG ---------------- */
    property int duration: 300  // Default break duration in seconds (5 minutes)
    property int timeRemaining: duration  // Countdown timer
    property string breakType: "break_reminder"  // Type: "eye_care" or "break_reminder"
    property bool testingMode: false  // Allow closing with Alt+F4 when true

    // Questionnaire state
    property bool questionnaireMode: false  // Switch from timer to questions after countdown
    property int currentQuestionIndex: 0  // Current question being displayed (0-2)
    property var answers: []  // Array to store user responses before saving

    // Hardcoded questions (TODO: Load from break-questions.json dynamically)
    property var questions: [
        {
            id: 1,
            text: "Before this break, were you focused on productive work?",
            type: "choice",
            answers: [
                { id: 1, text: "Yes, fully focused" },
                { id: 2, text: "Yes, but distracted" },
                { id: 3, text: "No, procrastinating" },
                { id: 4, text: "No, on break/personal time" }
            ]
        },
        {
            id: 2,
            text: "What will you do next?",
            type: "dropdown",
            answers: [
                { id: 1, text: "📚 Sem exam study" },
                { id: 2, text: "💻 Working on my project" },
                { id: 3, text: "👨‍💻 Coding/Development" },
                { id: 4, text: "📖 Learning something new" },
                { id: 5, text: "🎓 Doing online course" },
                { id: 6, text: "🎬 Watching movie/series" },
                { id: 7, text: "📱 Scrolling Instagram/Social media" },
                { id: 8, text: "🎮 Gaming/Entertainment" },
                { id: 9, text: "🗓️ Making future plans" },
                { id: 10, text: "🍔 Taking meal break" },
                { id: 11, text: "🚶 Going outside/Walk" },
                { id: 12, text: "😴 Rest/Sleep" }
            ]
        },
        {
            id: 3,
            text: "How confident are you that you won't procrastinate?",
            type: "choice",
            answers: [
                { id: 1, text: "Very confident - I have a clear plan" },
                { id: 2, text: "Somewhat confident" },
                { id: 3, text: "Not confident - I might get distracted" },
                { id: 4, text: "Unsure" }
            ]
        }
    ]

    // Response tracking
    property var currentQuestion: questions[currentQuestionIndex]
    property int selectedAnswerId: 0  // ID of selected answer (0 = none selected)
    property string textAnswer: ""  // Text input for text-type questions
    property var saveProcesses: []  // Keep Process references to prevent garbage collection
    property bool responsesSaved: false  // CRITICAL: Prevents duplicate saves on multi-monitor setups
                                         // Variants creates separate window per screen, but we only
                                         // want to save responses once to the database

    onCurrentQuestionIndexChanged: {
        // Reset state when question changes
        selectedAnswerId = 0
        textAnswer = ""
    }

    onCurrentQuestionChanged: {
        if (currentQuestion.type === "text") {
            // Schedule focus for text input
            Qt.callLater(function() {
                if (questionnaireMode) {
                    // The TextArea's Component.onCompleted will handle focus
                }
            })
        }
    }

    /* ---------------- FUNCTIONS ---------------- */
    /**
     * Save current answer and move to next question or finish
     * Stores answer in temporary array, actual DB save happens in saveAllResponses()
     */
    function saveResponse() {
        const answer = currentQuestion.type === "text" 
            ? textAnswer 
            : currentQuestion.answers.find(a => a.id === selectedAnswerId).text

        answers.push({
            question_id: currentQuestion.id,
            answer_id: selectedAnswerId,
            answer_text: answer
        })

        // Move to next question or finish
        if (currentQuestionIndex < questions.length - 1) {
            currentQuestionIndex++
            selectedAnswerId = 0
            textAnswer = ""
        } else {
            // All questions answered, save to database
            saveAllResponses()
        }
    }

    /**
     * Save all responses to database sequentially
     * MULTI-MONITOR SAFETY: Uses responsesSaved flag to prevent duplicate saves
     * when Variants creates multiple window instances (one per screen)
     */
    function saveAllResponses() {
        // Prevent duplicate saves from multiple monitor instances
        if (root.responsesSaved) {
            console.log("Responses already saved, closing app...")
            Qt.quit()
            return
        }
        
        root.responsesSaved = true  // Set flag before any DB operations
        console.log("Saving", answers.length, "responses...")
        saveNextResponse(0)
    }

    /**
     * Recursively save responses one at a time
     * Sequential saves ensure proper order and prevent database conflicts
     */
    function saveNextResponse(index) {
        if (index >= answers.length) {
            console.log("All responses saved! Closing app...")
            Qt.quit()
            return
        }

        const ans = answers[index]
        const scriptPath = Quickshell.env("HOME") + "/.config/hypr/productivity/save-break-response.py"
        
        // Escape the answer text for shell command
        const escapedText = (ans.answer_text || "").replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, ' ')
        
        // Create a new process for this response
        const processComponent = Qt.createQmlObject(`
            import Quickshell.Io
            import QtQuick
            Process {
                id: saveProc
                running: true
                command: [
                    "python3",
                    "${scriptPath}",
                    "${root.breakType}",
                    "${root.duration}",
                    "${ans.question_id}",
                    "${ans.answer_id}",
                    "${escapedText}"
                ]
                
                property int nextIndex: ${index}
                
                stdout: SplitParser {
                    onRead: data => {
                        console.log("✓ Q${ans.question_id}:", data)
                    }
                }
                
                stderr: SplitParser {
                    onRead: data => {
                        console.error("✗ Q${ans.question_id}:", data)
                    }
                }
                
                onRunningChanged: {
                    if (!running) {
                        // Process finished, save next response
                        root.saveNextResponse(nextIndex + 1)
                    }
                }
            }
        `, root)
        
        // Store reference to prevent garbage collection
        saveProcesses.push(processComponent)
    }

    /* ---------------- TIMER ---------------- */
    Timer {
        id: timer
        interval: 1000
        repeat: true

        onTriggered: {
            if (root.timeRemaining > 0) {
                root.timeRemaining--
            } else {
                stop()
                root.questionnaireMode = true
            }
        }
    }

    /* ---------------- MULTI-MONITOR SUPPORT ---------------- */
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            property var modelData
            screen: modelData
            visible: true
            color: root.theme.background || "#1e1e2e"

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            exclusiveZone: -1

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "break-enforcer"
            WlrLayershell.keyboardFocus: root.testingMode
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.Exclusive

        // Handle keyboard shortcuts
        Item {
            focus: true
            Keys.onPressed: (event) => {
                // Alt+F4 to close in testing mode
                if (root.testingMode && event.key === Qt.Key_F4 && (event.modifiers & Qt.AltModifier)) {
                    Qt.quit()
                    event.accepted = true
                }
            }
        }

        /* ================= TIMER MODE ================= */
        Item {
            anchors.fill: parent
            visible: !root.questionnaireMode

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 32
                width: 600

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.breakType === "eye_care"
                        ? "👁️ Eye Care Break"
                        : "🧘 Break Time"
                    font.pixelSize: 42
                    font.bold: true
                    color: root.theme.primary || "#89b4fa"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        const m = Math.floor(root.timeRemaining / 60)
                        const s = root.timeRemaining % 60
                        return m.toString().padStart(2, "0") + ":" +
                               s.toString().padStart(2, "0")
                    }
                    font.pixelSize: 96
                    font.family: "monospace"
                    font.bold: true
                    color: root.theme.tertiary || "#fab387"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Step away from your computer"
                    font.pixelSize: 22
                    color: root.theme.on_background || "#cdd6f4"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: testingMode
                        ? "TESTING MODE – window can be closed"
                        : "This window will unlock after the timer"
                    font.pixelSize: 14
                    color: testingMode ? (root.theme.error || "#f9e2af") : (root.theme.outline || "#6c7086")
                }
            }
        }

        /* ================= QUESTIONNAIRE MODE ================= */
        Item {
            anchors.fill: parent
            visible: root.questionnaireMode

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20
                width: 700

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "📊 Productivity Check (" + (root.currentQuestionIndex + 1) + "/" + root.questions.length + ")"
                    font.pixelSize: 36
                    font.bold: true
                    color: root.theme.primary || "#89b4fa"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 650
                    text: root.currentQuestion.text
                    font.pixelSize: 20
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: root.theme.on_background || "#cdd6f4"
                }

                /* Multiple choice answers */
                Repeater {
                    model: root.currentQuestion.type === "choice" ? root.currentQuestion.answers : []

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 10
                        border.width: 2
                        border.color: root.selectedAnswerId === modelData.id
                            ? (root.theme.primary || "#89b4fa")
                            : (root.theme.outline_variant || "#45475a")
                        color: root.selectedAnswerId === modelData.id
                            ? (root.theme.secondary_container || "#313244")
                            : (root.theme.surface || "#1e1e2e")

                        Text {
                            anchors.centerIn: parent
                            anchors.margins: 12
                            width: parent.width - 24
                            text: modelData.text
                            font.pixelSize: 18
                            color: root.selectedAnswerId === modelData.id
                                ? (root.theme.on_secondary_container || "#cdd6f4")
                                : (root.theme.on_surface || "#cdd6f4")
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectedAnswerId = modelData.id
                        }
                    }
                }

                /* Dropdown for activity selection - Custom scrollable dropdown */
                Item {
                    visible: root.currentQuestion.type === "dropdown"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.theme.surface || "#1e1e2e"
                        border.width: 2
                        border.color: root.theme.outline_variant || "#45475a"
                        
                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true
                            
                            ListView {
                                id: activityList
                                model: root.currentQuestion.type === "dropdown" ? root.currentQuestion.answers : []
                                spacing: 4
                                
                                delegate: Rectangle {
                                    width: activityList.width
                                    height: 44
                                    radius: 6
                                    color: root.selectedAnswerId === modelData.id
                                        ? (root.theme.primary || "#89b4fa")
                                        : (mouseArea.containsMouse ? (root.theme.secondary_container || "#313244") : "transparent")
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        width: parent.width - 24
                                        text: modelData.text
                                        font.pixelSize: 16
                                        color: root.selectedAnswerId === modelData.id
                                            ? (root.theme.on_primary || "#1e1e2e")
                                            : (root.theme.on_surface || "#cdd6f4")
                                        elide: Text.ElideRight
                                    }
                                    
                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.selectedAnswerId = modelData.id
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                /* Text input for open-ended questions */
                Rectangle {
                    id: textInputContainer
                    visible: root.currentQuestion.type === "text"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 10
                    border.width: 2
                    border.color: textInput.activeFocus 
                        ? (root.theme.primary || "#89b4fa")
                        : (root.theme.outline_variant || "#45475a")
                    color: root.theme.surface || "#1e1e2e"

                    Component.onCompleted: {
                        if (visible && root.currentQuestion.type === "text") {
                            textInput.forceActiveFocus()
                        }
                    }

                    onVisibleChanged: {
                        if (visible && root.currentQuestion.type === "text") {
                            Qt.callLater(function() {
                                textInput.forceActiveFocus()
                            })
                        }
                    }

                    TextArea {
                        id: textInput
                        anchors.fill: parent
                        anchors.margins: 12
                        text: root.textAnswer
                        placeholderText: root.currentQuestion.placeholder || "Type your answer..."
                        placeholderTextColor: root.theme.outline || "#6c7086"
                        font.pixelSize: 16
                        color: root.theme.on_surface || "#cdd6f4"
                        wrapMode: TextEdit.Wrap
                        background: null
                        selectByMouse: true
                        selectionColor: root.theme.primary || "#89b4fa"
                        activeFocusOnTab: true
                        focus: root.currentQuestion.type === "text"

                        Component.onCompleted: {
                            if (root.currentQuestion.type === "text") {
                                forceActiveFocus()
                            }
                        }

                        onTextChanged: {
                            root.textAnswer = text
                            root.selectedAnswerId = text.length > 0 ? 1 : 0
                        }

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ControlModifier) {
                                // Ctrl+Enter to submit
                                if (root.selectedAnswerId !== 0) {
                                    root.saveResponse()
                                }
                                event.accepted = true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: textInput.forceActiveFocus()
                        propagateComposedEvents: true
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 56
                    radius: 10
                    color: root.selectedAnswerId === 0 
                        ? (root.theme.surface_dim || "#45475a")
                        : (root.theme.primary || "#89b4fa")

                    Text {
                        anchors.centerIn: parent
                        text: root.currentQuestionIndex < root.questions.length - 1 
                            ? "Next Question →"
                            : "Complete Break"
                        font.pixelSize: 20
                        font.bold: true
                        color: root.selectedAnswerId === 0 
                            ? (root.theme.outline || "#6c7086")
                            : (root.theme.on_primary || "#1e1e2e")
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.selectedAnswerId !== 0
                        onClicked: root.saveResponse()
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.selectedAnswerId === 0
                    text: "⚠️ Please select an option"
                    font.pixelSize: 14
                    color: root.theme.error || "#f9e2af"
                }
            }
        }
        }
    }
}

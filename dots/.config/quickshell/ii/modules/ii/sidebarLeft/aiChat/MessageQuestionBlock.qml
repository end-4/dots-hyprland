pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Renders an AskUserQuestion command fence as one box for the whole question set:
 * a command-block style title bar, then per question its text, option pills and
 * a free-text pill, and a Submit/Dismiss pair modeled after command
 * approval. Submit sends one permission response; questions with no selection
 * are skipped. Dismiss denies the request. The fence body is the tool's JSON
 * input; once submitted it is rewritten to {questions, selections} with an
 * :answered flag and renders statically. The header carries the outcome and the
 * box collapses, folding itself away if the model abandons the question.
 */
ColumnLayout {
    id: root
    property var segmentContent: ({})
    property var segmentLang: ""
    property var messageData: {}
    property bool isPendingCommand: false

    property bool submitted: (segmentLang ?? "").split(":").includes("answered")
    property bool dismissed: (segmentLang ?? "").split(":").includes("denied")
    property bool streaming: (segmentLang ?? "").split(":").includes("streaming")
    // The strategy re-closes the still-streaming tool input before writing it, so the body is
    // always valid JSON and the box renders progressively off a plain parse
    property var parsed: {
        try {
            return JSON.parse(String(root.segmentContent ?? ""));
        } catch (e) {
            return null;
        }
    }
    property var questions: parsed?.questions ?? []
    property bool interactive: isPendingCommand && (messageData?.functionPending ?? false) && !submitted && !dismissed
    // A question left un-answered reads as dismissed like an explicitly dismissed one: either way
    // it is spent, and the fence alone cannot tell them apart since both sit at :pending
    readonly property string state: {
        if (root.submitted) return "answered";
        if (root.streaming) return "streaming";
        if (root.dismissed || !root.interactive) return "dismissed";
        return "pending";
    }
    readonly property var stateLabels: ({
        "pending": Translation.tr("pending"),
        "answered": Translation.tr("answered"),
        "dismissed": Translation.tr("dismissed"),
    })
    // Streaming has no label: the message's own loading indicator already says as much
    readonly property string stateLabel: root.stateLabels[root.state] ?? ""

    // Open by default since a question is addressed to the user; a spent one folds away.
    // Clicking the header replaces this binding
    property bool collapsed: root.state === "dismissed"
    property var collapseAnimation: questionContentColumn.implicitHeight > 40
        ? Appearance.animation.elementMoveEnter : Appearance.animation.elementMoveFast

    // Picks live in the service until Submit writes them into the fence body
    function chosenLabels(question) {
        if (root.interactive) return Ai.questionSelections[question] ?? [];
        return root.parsed?.selections?.[question] ?? [];
    }

    // Committed answer parts that match no option label (free-text answers)
    function freeTextOf(question, options) {
        const labels = (options ?? []).map(opt => opt.label);
        return chosenLabels(question).filter(part => !labels.includes(part)).join(", ");
    }

    // The gap between the two cards lives in the collapsing wrapper, so it closes with them
    spacing: 0
    property real questionBlockComponentSpacing: 2
    property real pillTextInset: 8

    // Animated slot for the multiSelect checkmark: its width changes continuously,
    // so the pill and text stay in step instead of the icon popping in a single frame
    component CheckSlot: Item {
        id: slot
        required property bool checked
        implicitHeight: checkIcon.implicitHeight
        implicitWidth: checked ? checkIcon.implicitWidth + 4 : 0
        clip: true
        Behavior on implicitWidth {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
        }
        MaterialSymbol {
            id: checkIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            iconSize: Appearance.font.pixelSize.normal
            // Only ever visible on a selected pill
            color: Appearance.colors.colOnPrimary
            text: "check"
            opacity: slot.checked ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    Rectangle { // Title bar, mirrors the command block header
        visible: root.questions.length > 0
        Layout.fillWidth: true
        topLeftRadius: Appearance.rounding.small
        topRightRadius: Appearance.rounding.small
        // Rounds off into a standalone card once the body is gone
        bottomLeftRadius: root.collapsed ? Appearance.rounding.small : Appearance.rounding.unsharpen
        bottomRightRadius: bottomLeftRadius
        color: Appearance.colors.colSurfaceContainerHighest
        // Row padded by 3 with the icon carrying the rest, as in the think and command headers
        implicitHeight: titleRowLayout.implicitHeight + 3 * 2

        Behavior on bottomLeftRadius {
            NumberAnimation {
                duration: root.collapseAnimation.duration
                easing.type: root.collapseAnimation.type
                easing.bezierCurve: root.collapseAnimation.bezierCurve
            }
        }

        MouseArea { // Click the bar to collapse or reveal
            id: titleMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.collapsed = !root.collapsed
        }

        RowLayout {
            id: titleRowLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 13
            anchors.rightMargin: 10
            spacing: 5

            MaterialSymbol {
                Layout.topMargin: 7
                Layout.bottomMargin: 7
                color: Appearance.colors.colOnLayer2
                text: "question_exchange"
            }
            StyledText {
                Layout.leftMargin: 5
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
                text: root.questions.length > 1 ? Translation.tr("Questions") : Translation.tr("Question")
            }
            Rectangle {
                visible: root.stateLabel.length > 0
                implicitWidth: 4
                implicitHeight: 4
                radius: implicitWidth / 2
                color: Appearance.colors.colOnLayer1Inactive
            }
            StyledText {
                visible: root.stateLabel.length > 0
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                // As in the command block, the outcomes that cost the user something stand out
                color: root.state === "dismissed"
                    ? Appearance.colors.colTertiary : Appearance.colors.colSubtext
                text: root.stateLabel
            }
            Item { Layout.fillWidth: true }
            ExpandButton {
                expanded: !root.collapsed
                headerHovered: titleMouseArea.containsMouse
                onClicked: root.collapsed = !root.collapsed
            }
        }
    }

    CollapsibleContent {
        visible: root.questions.length > 0
        collapsed: root.collapsed
        contentHeight: questionBody.implicitHeight + root.questionBlockComponentSpacing
        animation: root.collapseAnimation
        // While the input streams the body grows on its own; animating that reads as a stutter
        animated: !root.streaming

        Rectangle { // Questions, option pills, and the Submit/Dismiss pair
            id: questionBody
            // Top-anchored: the hint changes this body's height while expanded, and a bottom
            // anchor would push that growth out of the window, dragging the pills up with it
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            topLeftRadius: Appearance.rounding.unsharpen
            topRightRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: Appearance.rounding.small
            bottomRightRadius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            implicitHeight: questionContentColumn.implicitHeight + 10 * 2

            MouseArea { // Click on box dead space to unfocus the text pill
                anchors.fill: parent
                onPressed: root.forceActiveFocus()
            }

            ColumnLayout {
                id: questionContentColumn
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 8

                Repeater {
                    model: ScriptModel {
                        values: root.questions
                    }
                    delegate: ColumnLayout { // One section per question
                        id: questionSection
                        required property var modelData
                        required property int index
                        property string question: modelData.question ?? ""
                        property bool multiSelect: modelData.multiSelect ?? false

                        Layout.fillWidth: true
                        Layout.topMargin: index > 0 ? 6 : 0
                        spacing: 8

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer1
                            text: questionSection.question
                        }

                        Flow {
                            id: optionsFlow
                            Layout.fillWidth: true
                            spacing: 5

                            // The box's own height animates as the flow reflows, so pills that
                            // change row travel with it instead of teleporting. Off while the
                            // options are still arriving, where every new pill reflows the rest
                            move: Transition {
                                enabled: !root.streaming
                                NumberAnimation {
                                    properties: "x,y"
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                }
                            }

                            Repeater {
                                model: ScriptModel {
                                    values: questionSection.modelData.options ?? []
                                }
                                delegate: GroupButton { // Styled like the command suggestion pills
                                    id: optionPill
                                    required property var modelData
                                    property string label: modelData.label ?? ""
                                    enabled: root.interactive
                                    bounce: false
                                    // The checkmark slot animates its own width; the pill follows it
                                    // rigidly so the size change is animated exactly once
                                    enableImplicitWidthAnimation: false
                                    buttonRadius: optionPill.down ? Appearance.rounding.verysmall : Appearance.rounding.small
                                    horizontalPadding: root.pillTextInset
                                    verticalPadding: 6
                                    toggled: root.chosenLabels(questionSection.question).includes(label)
                                    colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                    colBackgroundActive: Appearance.colors.colSecondaryContainerActive
                                    contentItem: RowLayout {
                                        spacing: 0
                                        CheckSlot {
                                            checked: questionSection.multiSelect && optionPill.toggled
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        StyledText {
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            horizontalAlignment: Text.AlignHCenter
                                            color: optionPill.toggled ? Appearance.colors.colOnPrimary
                                                : Appearance.colors.colOnSecondaryContainer
                                            text: optionPill.label
                                        }
                                    }
                                    onClicked: {
                                        if (questionSection.multiSelect) {
                                            Ai.toggleQuestionOption(questionSection.question, optionPill.label);
                                        } else {
                                            Ai.setQuestionSelection(questionSection.question,
                                                optionPill.toggled ? [] : [optionPill.label]);
                                        }
                                    }
                                    PillHint {
                                        bounds: questionContentColumn
                                        text: optionPill.modelData.description ?? ""
                                    }
                                }
                            }

                            Rectangle { // Free-text pill, expands with its content
                                id: freeTextPill
                                // Renders selected exactly like an option pill: lit when its
                                // text is among the question's current picks
                                PillHint {
                                    bounds: questionContentColumn
                                    extraVisibleCondition: freeTextHover.hovered
                                    text: freeTextPill.committed
                                        ? Translation.tr("Your own answer")
                                        : Translation.tr("Type your own answer")
                                }
                                HoverHandler {
                                    id: freeTextHover
                                    cursorShape: root.interactive ? Qt.IBeamCursor : Qt.ArrowCursor
                                }
                                // The input is inset, so a click on the pill's padding or
                                // checkmark would fall through and blur it instead of focusing
                                TapHandler {
                                    enabled: root.interactive
                                    onTapped: freeTextInput.forceActiveFocus()
                                }
                                StateOverlay { // Hover feedback, as the option pills get
                                    anchors.fill: parent
                                    topLeftRadius: freeTextPill.radius
                                    topRightRadius: freeTextPill.radius
                                    bottomLeftRadius: freeTextPill.radius
                                    bottomRightRadius: freeTextPill.radius
                                    hover: root.interactive && freeTextHover.hovered
                                    // Focus is already called out by the pill's own border, which
                                    // is how M3 marks a focused text field
                                    contentColor: freeTextPill.committed
                                        ? Appearance.colors.colOnPrimary
                                        : Appearance.colors.colOnSecondaryContainer
                                }
                                property bool committed: freeTextInput.text.trim().length > 0
                                    && root.chosenLabels(questionSection.question).includes(freeTextInput.text.trim())
                                // In the submitted transcript the pill stays, showing the custom answer
                                property string historyFreeText: root.interactive || root.streaming
                                    ? "" : root.freeTextOf(questionSection.question, questionSection.modelData.options ?? [])
                                visible: root.interactive || root.streaming || historyFreeText.length > 0
                                radius: Appearance.rounding.small
                                color: committed ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                                border.width: freeTextInput.activeFocus && !committed ? 1 : 0
                                border.color: Appearance.colors.colPrimary
                                implicitHeight: freeTextInput.implicitHeight + 6 * 2
                                // Off unwrapped metrics: the input's own content size would depend
                                // right back on this width. The spare pixel is its cursor column
                                implicitWidth: freeTextInput.text.length > 0
                                    ? Math.min(Math.ceil(freeTextMetrics.advanceWidth) + 1 + root.pillTextInset * 2 + freeCheckSlot.width,
                                        optionsFlow.width)
                                    : 120

                                TextMetrics {
                                    id: freeTextMetrics
                                    font: freeTextInput.font
                                    text: freeTextInput.text
                                }

                                CheckSlot {
                                    id: freeCheckSlot
                                    checked: questionSection.multiSelect && freeTextPill.committed
                                    anchors.left: parent.left
                                    anchors.leftMargin: root.pillTextInset
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                TextEdit {
                                    id: freeTextInput
                                    enabled: root.interactive
                                    // Interactive typing replaces this binding; for a loaded
                                    // transcript it fills in the submitted custom answer
                                    text: freeTextPill.historyFreeText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: root.pillTextInset + freeCheckSlot.width
                                    anchors.rightMargin: root.pillTextInset
                                    wrapMode: TextEdit.Wrap
                                    clip: true
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: freeTextPill.committed ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                                    selectByMouse: true
                                    // Editing only happens uncommitted (focus un-commits), so the
                                    // background is always colSecondaryContainer; primary stands out
                                    selectedTextColor: Appearance.colors.colOnPrimary
                                    selectionColor: Appearance.colors.colPrimary

                                    property string placeholder: Translation.tr("Other...")
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: freeTextInput.text.length === 0 && !freeTextInput.activeFocus
                                        font: freeTextInput.font
                                        color: Appearance.colors.colSubtext
                                        text: freeTextInput.placeholder
                                    }

                                    MouseArea { // Hover only; presses belong to the TextInput
                                        anchors.fill: parent
                                        acceptedButtons: Qt.NoButton
                                        cursorShape: root.interactive ? Qt.IBeamCursor : Qt.ArrowCursor
                                    }

                                    // The one custom entry this pill has contributed; edits replace it
                                    property string committedText: ""

                                    // Single-select: text becomes the answer. multiSelect: text joins
                                    // the picks like a toggled chip
                                    function commitFreeText() {
                                        const answer = text.trim();
                                        if (questionSection.multiSelect) {
                                            if (committedText.length > 0 && committedText !== answer
                                                    && root.chosenLabels(questionSection.question).includes(committedText)) {
                                                Ai.toggleQuestionOption(questionSection.question, committedText);
                                            }
                                            if (answer.length > 0
                                                    && !root.chosenLabels(questionSection.question).includes(answer)) {
                                                Ai.toggleQuestionOption(questionSection.question, answer);
                                            }
                                            committedText = answer;
                                        } else if (answer.length > 0) {
                                            // Don't clobber an option picked while this field kept focus
                                            const current = root.chosenLabels(questionSection.question);
                                            if (current.length === 0 || current.includes(committedText)) {
                                                Ai.setQuestionSelection(questionSection.question, [answer]);
                                                committedText = answer;
                                            }
                                        }
                                    }

                                    // Focus un-commits this pill's entry (single-select: the whole
                                    // selection) so it drops back to the typing look; leaving
                                    // with text commits — Enter also commits, but isn't required
                                    onActiveFocusChanged: {
                                        if (!root.interactive) return;
                                        if (activeFocus) {
                                            if (questionSection.multiSelect) {
                                                if (committedText.length > 0
                                                        && root.chosenLabels(questionSection.question).includes(committedText)) {
                                                    Ai.toggleQuestionOption(questionSection.question, committedText);
                                                }
                                            } else {
                                                Ai.setQuestionSelection(questionSection.question, []);
                                            }
                                        } else {
                                            commitFreeText();
                                        }
                                    }

                                    // Blur commits, so Enter just drops focus. Shift+Enter is left
                                    // to the editor for a deliberate newline
                                    Keys.onPressed: event => {
                                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                                && !(event.modifiers & Qt.ShiftModifier)) {
                                            root.forceActiveFocus();
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }

                        }
                    }
                }

                RowLayout { // Submit/Dismiss pair, mirrors command approval
                    visible: root.interactive || root.streaming
                    Layout.fillWidth: true
                    Layout.topMargin: 2

                    Item { Layout.fillWidth: true }
                    ButtonGroup {
                        GroupButton {
                            enabled: root.interactive
                            // The default hover (colLayer1Hover) is invisible on this
                            // box's colLayer2 background
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            colBackgroundActive: Appearance.colors.colLayer2Active
                            contentItem: StyledText {
                                text: Translation.tr("Dismiss")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer2
                            }
                            onClicked: Ai.rejectCommand(root.messageData)
                        }
                        GroupButton {
                            enabled: root.interactive
                            toggled: true
                            // colBackground carries the fill so it survives the disabled state
                            colBackground: Appearance.colors.colPrimary
                            contentItem: StyledText {
                                text: Translation.tr("Submit")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnPrimary
                            }
                            onClicked: {
                                // Commit free text still sitting in a focused pill first
                                root.forceActiveFocus();
                                Ai.submitQuestions(root.messageData);
                            }
                        }
                    }
                }
            }
        }
    }
}

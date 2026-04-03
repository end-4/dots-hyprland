import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

LazyLoader {
    id: root

    signal requestClose()

    property Item hoverTarget
    property bool forcedOpen: false
    property var sessions: []
    property int sessionCount: 0
    property string selectedSessionId: sessions.length > 0 ? (sessions[0].session_id ?? "") : ""
    property string viewMode: "list"
    property string choiceScriptPath: `${Directories.scriptPath}/orbitbar/send_choice.py`
    property string focusScriptPath: `${Directories.scriptPath}/orbitbar/focus_terminal.py`

    readonly property real horizontalPadding: 14
    readonly property real verticalPadding: 14
    readonly property real panelWidth: viewMode === "list" ? 404 : 548

    readonly property var selectedSession: {
        if (sessions.length === 0)
            return null;
        const matched = sessions.find(session => session.session_id === selectedSessionId);
        return matched ?? sessions[0];
    }
    readonly property bool selectedHasActions: (selectedSession?.actions ?? []).length > 0
    readonly property bool selectedHasOptions: (selectedSession?.options ?? []).length > 0
    readonly property bool selectedHasPreview: (selectedSession?.preview ?? "").length > 0
    readonly property bool selectedHasRecent: (selectedSession?.recent ?? []).length > 0
    readonly property bool selectedNeedsInput: selectedHasActions || selectedHasOptions || (selectedSession?.requires_action ?? false)

    active: hoverTarget && (hoverTarget.containsMouse || forcedOpen)

    onSessionsChanged: {
        if (sessions.length === 0) {
            selectedSessionId = "";
            viewMode = "list";
            return;
        }

        if (!selectedSessionId || !sessions.some(session => session.session_id === selectedSessionId))
            selectedSessionId = sessions[0].session_id ?? "";
    }

    function openThread(sessionId) {
        selectedSessionId = sessionId;
        viewMode = "detail";
    }

    function resetView() {
        viewMode = "list";
    }

    function submitChoice(option) {
        if (!selectedSession?.pid || !option?.id)
            return;
        Quickshell.execDetached([
            "python",
            choiceScriptPath,
            "--pid",
            `${selectedSession.pid}`,
            "--choice-id",
            `${option.id}`,
        ]);

        if ((option.id === "allow_once" || option.id === "allow_session") && (selectedSession?.sensitive_input_required ?? false)) {
            focusTerminal();
            return;
        }

        requestClose();
    }

    function focusTerminal() {
        if (!selectedSession?.window_address)
            return;
        Quickshell.execDetached([
            "python",
            focusScriptPath,
            "--address",
            `${selectedSession.window_address}`,
            "--special-name",
            "agents",
            "--move-to-special",
            "--show-special",
            "--focus",
        ]);
        requestClose();
    }

    function dispatchAction(action) {
        if (!action?.id)
            return;
        if (action.id === "focus_terminal" || action.id === "show_terminal")
            focusTerminal();
    }

    function statusColorFor(status) {
        switch (status) {
        case "approval_required":
            return Appearance.colors.colSecondary;
        case "question":
            return Appearance.colors.colPrimary;
        case "error":
            return Appearance.colors.colError;
        case "done":
            return Appearance.colors.colPrimary;
        default:
            return Appearance.colors.colTertiary;
        }
    }

    component ThreadBadge: Rectangle {
        required property string label

        radius: 8
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colOutlineVariant.r, Appearance.colors.colOutlineVariant.g, Appearance.colors.colOutlineVariant.b, 0.4)
        implicitWidth: badgeText.implicitWidth + 12
        implicitHeight: badgeText.implicitHeight + 6

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            text: parent.label
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smallest
        }
    }

    component SessionMetaRow: Row {
        required property var thread

        spacing: 6

        ThreadBadge {
            visible: !!parent.thread?.tool
            label: `${parent.thread?.tool ?? ""}`
        }

        ThreadBadge {
            visible: !!parent.thread?.terminal_app
            label: `${parent.thread?.terminal_app ?? ""}`
        }

        StyledText {
            visible: text.length > 0
            text: parent.thread?.age ?? ""
            color: "#bfc0c7"
            font.pixelSize: Appearance.font.pixelSize.smallest
        }
    }

    component ActionPill: Rectangle {
        required property string label
        property bool emphasized: false

        radius: 10
        color: emphasized ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
        border.width: 1
        border.color: emphasized ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
        implicitWidth: pillText.implicitWidth + 18
        implicitHeight: pillText.implicitHeight + 10

        StyledText {
            id: pillText
            anchors.centerIn: parent
            text: parent.label
            color: parent.emphasized ? Appearance.colors.colOnPrimaryContainer : "#ffffff"
            font.pixelSize: Appearance.font.pixelSize.smallest
        }
    }

    component DetailCard: Rectangle {
        width: root.panelWidth - root.horizontalPadding * 2
        radius: 16
        color: Appearance.colors.colSurfaceContainer
        border.width: 1
        border.color: Qt.rgba(root.statusColorFor(root.selectedSession?.status ?? "idle").r, root.statusColorFor(root.selectedSession?.status ?? "idle").g, root.statusColorFor(root.selectedSession?.status ?? "idle").b, 0.3)
        implicitHeight: detailBody.childrenRect.height + 24

        Column {
            id: detailBody
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10

            StyledText {
                width: parent.width
                text: root.selectedSession?.title ?? "Thread"
                color: "#ffffff"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            SessionMetaRow {
                thread: root.selectedSession
            }

            StyledText {
                width: parent.width
                text: root.selectedSession?.detail ?? "No details"
                color: "#ffffff"
                opacity: 0.92
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }

            Rectangle {
                visible: root.selectedHasPreview
                width: parent.width
                radius: 12
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant
                implicitHeight: previewText.implicitHeight + 18

                StyledText {
                    id: previewText
                    x: 9
                    y: 9
                    width: parent.width - 18
                    text: root.selectedSession?.preview ?? ""
                    color: "#ffffff"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    wrapMode: Text.Wrap
                }
            }

            Column {
                visible: root.selectedHasOptions
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.selectedSession?.options ?? []

                    delegate: RippleButton {
                        readonly property var option: modelData

                        implicitHeight: optionBody.childrenRect.height + 16
                        implicitWidth: parent.width
                        buttonRadius: 12
                        colBackground: Appearance.colors.colPrimaryContainer
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colBackgroundToggled: colBackground
                        colBackgroundToggledHover: colBackgroundHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        colRippleToggled: colRipple
                        releaseAction: () => root.submitChoice(option)

                        contentItem: Column {
                            id: optionBody
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            StyledText {
                                width: parent.width
                                text: `${option.label ?? option.id ?? ""}`
                                color: Appearance.colors.colOnPrimaryContainer
                                font.pixelSize: Appearance.font.pixelSize.small
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                visible: text.length > 0
                                width: parent.width
                                text: `${option.description ?? ""}`
                                color: Appearance.colors.colOnPrimaryContainer
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                opacity: 0.82
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            Flow {
                visible: root.selectedHasActions
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.selectedSession?.actions ?? []

                    delegate: RippleButton {
                        readonly property var actionModel: modelData

                        implicitWidth: actionBody.implicitWidth + 18
                        implicitHeight: actionBody.implicitHeight + 10
                        buttonRadius: 10
                        colBackground: actionModel.emphasized ?? false ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        colBackgroundHover: actionModel.emphasized ?? false ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                        colBackgroundToggled: colBackground
                        colBackgroundToggledHover: colBackgroundHover
                        colRipple: actionModel.emphasized ?? false ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer1Active
                        colRippleToggled: colRipple
                        releaseAction: () => root.dispatchAction(actionModel)

                        contentItem: StyledText {
                            id: actionBody
                            anchors.centerIn: parent
                            text: `${actionModel.label ?? actionModel.id ?? actionModel}`
                            color: actionModel.emphasized ?? false ? Appearance.colors.colOnPrimaryContainer : "#ffffff"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }
                }
            }

            Row {
                visible: !!root.selectedSession && !root.selectedNeedsInput
                spacing: 10

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.14)

                    StyledText {
                        anchors.centerIn: parent
                        text: "✓"
                        color: Appearance.colors.colPrimary
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                StyledText {
                    text: "No action needed"
                    color: "#ffffff"
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }
    }

    component RecentCard: Rectangle {
        visible: root.selectedHasRecent
        width: root.panelWidth - root.horizontalPadding * 2
        radius: 16
        color: Appearance.colors.colSurfaceContainer
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colOutlineVariant.r, Appearance.colors.colOutlineVariant.g, Appearance.colors.colOutlineVariant.b, 0.4)
        implicitHeight: recentBody.childrenRect.height + 24

        Column {
            id: recentBody
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 8

            StyledText {
                text: "Recent activity"
                color: "#ffffff"
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
            }

            Repeater {
                model: root.selectedSession?.recent ?? []

                delegate: Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        y: 6
                        width: 4
                        height: 4
                        radius: 2
                        color: root.statusColorFor(root.selectedSession?.status ?? "idle")
                    }

                    StyledText {
                        width: parent.width - 12
                        text: `${modelData}`
                        color: "#ffffff"
                        opacity: 0.82
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    component: PanelWindow {
        id: popupWindow

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors.top: true
        anchors.left: true

        implicitWidth: panel.implicitWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: panel.implicitHeight + Appearance.sizes.elevationMargin * 2

        margins {
            left: root.QsWindow?.mapFromItem(root.hoverTarget, (root.hoverTarget.width - panel.implicitWidth) / 2, 0).x ?? 0
            top: Appearance.sizes.barHeight + 4
        }

        mask: Region {
            item: panel
        }

        StyledRectangularShadow {
            target: panel
            opacity: 0.45
        }

        Rectangle {
            id: panel
            anchors.fill: parent
            anchors.margins: Appearance.sizes.elevationMargin
            radius: 18
            color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.96)
            border.width: 1
            border.color: Qt.rgba(Appearance.colors.colOutlineVariant.r, Appearance.colors.colOutlineVariant.g, Appearance.colors.colOutlineVariant.b, 0.45)
            implicitWidth: root.panelWidth
            implicitHeight: (root.viewMode === "list" ? listBody.implicitHeight : detailBody.implicitHeight) + root.verticalPadding * 2

            Item {
                anchors.fill: parent

                Item {
                    id: listBody
                    x: root.horizontalPadding
                    y: root.verticalPadding
                    width: parent.width - root.horizontalPadding * 2
                    visible: root.viewMode === "list"
                    implicitHeight: listColumn.childrenRect.height

                    Column {
                        id: listColumn
                        width: parent.width
                        spacing: 8

                        StyledText {
                            text: root.sessionCount === 1 ? "1 thread" : `${root.sessionCount} threads`
                            color: Appearance.colors.colOnSurface
                            font.pixelSize: Appearance.font.pixelSize.large
                        }

                        Repeater {
                            model: root.sessions

                            delegate: RippleButton {
                                required property var modelData
                                readonly property bool primary: (modelData?.session_id ?? "") === (root.sessions[0]?.session_id ?? "")
                                readonly property color statusColor: root.statusColorFor(modelData?.status ?? "idle")
                                readonly property real textRightEdge: metaRow.visible ? metaRow.x - 10 : parent.width - 14
                                readonly property string summaryText: `${modelData?.detail ?? modelData?.preview ?? ""}`
                                readonly property string actionText: modelData?.requires_action ? "Action needed" : "No action needed"

                                implicitWidth: parent.width
                                implicitHeight: primary ? 88 : 40
                                buttonRadius: primary ? 14 : 12
                                colBackground: primary ? Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.78) : Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.52)
                                colBackgroundHover: primary ? Appearance.colors.colSurfaceContainerHighestHover : Appearance.colors.colSurfaceContainerHighest
                                colBackgroundToggled: colBackground
                                colBackgroundToggledHover: colBackgroundHover
                                colRipple: primary ? Appearance.colors.colSurfaceContainerHighestActive : Appearance.colors.colLayer1Active
                                colRippleToggled: colRipple
                                releaseAction: () => root.openThread(modelData.session_id ?? "")

                                contentItem: Item {
                                    anchors.fill: parent

                                    Rectangle {
                                        x: 12
                                        y: primary ? 15 : 16
                                        width: primary ? 8 : 7
                                        height: primary ? 8 : 7
                                        radius: width / 2
                                        color: parent.parent.statusColor
                                    }

                                    SessionMetaRow {
                                        id: metaRow
                                        x: parent.width - implicitWidth - 12
                                        y: primary ? 10 : 10
                                        visible: true
                                        thread: modelData
                                    }

                                    Text {
                                        x: 30
                                        y: primary ? 8 : 8
                                        width: Math.max(80, parent.parent.textRightEdge - 30)
                                        text: `${modelData?.title ?? modelData?.session_id ?? "untitled"}`
                                        color: "#ffffff"
                                        font.pixelSize: primary ? 17 : 14
                                        font.weight: primary ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        renderType: Text.NativeRendering
                                    }

                                    Text {
                                        visible: primary
                                        x: 30
                                        y: 33
                                        width: Math.max(80, parent.parent.textRightEdge - 30)
                                        text: parent.parent.summaryText
                                        color: "#a9adb5"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        renderType: Text.NativeRendering
                                    }

                                    Text {
                                        visible: primary
                                        x: 30
                                        y: 56
                                        width: Math.max(80, parent.parent.textRightEdge - 30)
                                        text: parent.parent.actionText
                                        color: modelData?.requires_action ? "#55a8ff" : "#52d88a"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.sessions.length === 0
                            radius: 14
                            color: Appearance.colors.colSurfaceContainer
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant
                            width: parent.width
                            height: 56

                            StyledText {
                                anchors.centerIn: parent
                                text: "No active threads"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }

                Item {
                    id: detailBody
                    x: root.horizontalPadding
                    y: root.verticalPadding
                    width: parent.width - root.horizontalPadding * 2
                    visible: root.viewMode === "detail"
                    implicitHeight: detailColumn.childrenRect.height

                    Column {
                        id: detailColumn
                        width: parent.width
                        spacing: 10

                        RippleButton {
                            implicitWidth: 36
                            implicitHeight: 32
                            buttonRadius: 10
                            colBackground: Appearance.colors.colLayer1
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            releaseAction: root.resetView

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: "←"
                                color: "#ffffff"
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }

                        DetailCard {}
                        RecentCard {}
                    }
                }
            }
        }
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property real panelWidth: 440
    readonly property real panelHeight: 340
    readonly property real panelPadding: 20
    property string scratchpadContents: ""
    property bool pendingReload: false

    Component.onCompleted: scratchpadFile.reload()

    function saveScratchpad(text) {
        scratchpadContents = text
        scratchpadFile.setText(scratchpadContents)
    }

    PanelWindow {
        id: scratchpadWindow
        screen: Quickshell.primaryScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        implicitWidth: panelWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: panelHeight + Appearance.sizes.elevationMargin * 2
        WlrLayershell.namespace: "quickshell:scratchpad"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        visible: GlobalStates.scratchpadOpen || scratchpadBackground.opacity > 0.01

        readonly property real openMargin: (Config.options.bar.bottom ? Appearance.sizes.hyprlandGapsOut + Appearance.sizes.elevationMargin
                                                                     : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut + Appearance.sizes.elevationMargin)
        readonly property real hiddenMargin: -panelHeight - Appearance.sizes.barHeight - Appearance.sizes.elevationMargin * 2
        property real topOffset: GlobalStates.scratchpadOpen ? openMargin : hiddenMargin

        anchors {
            top: true
            right: true
        }

        margins {
            top: scratchpadWindow.topOffset
            right: Appearance.sizes.hyprlandGapsOut
        }

        Behavior on topOffset {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        mask: Region {
            item: scratchpadBackground
        }

        StyledRectangularShadow {
            target: scratchpadBackground
        }

        Rectangle {
            id: scratchpadBackground
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Appearance.sizes.elevationMargin
                rightMargin: Appearance.sizes.elevationMargin
            }
            width: panelWidth
            height: panelHeight
            radius: Appearance.rounding.windowRounding
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            opacity: GlobalStates.scratchpadOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            ColumnLayout {
                id: scratchpadLayout
                anchors {
                    fill: parent
                    margins: panelPadding
                }
                spacing: 14
                Layout.fillHeight: true

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    StyledText {
                        text: Translation.tr("Scratchpad")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        id: statusLabel
                        text: saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved")
                        color: saveDebounce.running ? Appearance.colors.colSubtext : Appearance.m3colors.m3outline
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                ScrollView {
                    id: editorScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 10
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    StyledTextArea {
                        id: scratchpadInput
                        wrapMode: TextEdit.Wrap
                        placeholderText: Translation.tr("Write...")
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.PlainText
                        background: null
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                                GlobalStates.scratchpadOpen = false
                                event.accepted = true
                            }
                        }
                        onTextChanged: {
                            if (scratchpadInput.activeFocus) {
                                saveDebounce.restart()
                            }
                        }
                    }
                }
            }

        }

        Timer {
            id: saveDebounce
            interval: 500
            repeat: false
            onTriggered: saveScratchpad(scratchpadInput.text)
        }

        Connections {
            target: GlobalStates
            function onScratchpadOpenChanged() {
                if (GlobalStates.scratchpadOpen) {
                    pendingReload = true
                    scratchpadFile.reload()
                } else {
                    if (saveDebounce.running) {
                        saveDebounce.stop()
                    }
                    saveScratchpad(scratchpadInput.text)
                }
            }
        }

    }

    FileView {
        id: scratchpadFile
        path: Qt.resolvedUrl(Directories.scratchpadPath)
        onLoaded: {
            scratchpadContents = scratchpadFile.text()
            if (!scratchpadInput)
                return
            if (scratchpadInput.text === scratchpadContents)
                return
            const previousCursor = scratchpadInput.cursorPosition
            const previousAnchor = scratchpadInput.selectionStart
            scratchpadInput.text = scratchpadContents
            const maxPos = scratchpadInput.text.length
            scratchpadInput.cursorPosition = Math.min(previousCursor, maxPos)
            scratchpadInput.selectionStart = Math.min(previousAnchor, maxPos)
            scratchpadInput.selectionEnd = scratchpadInput.cursorPosition
            if (pendingReload && GlobalStates.scratchpadOpen) {
                pendingReload = false
                Qt.callLater(() => {
                    scratchpadInput.forceActiveFocus()
                    scratchpadInput.cursorPosition = scratchpadInput.text.length
                    scratchpadInput.selectionStart = scratchpadInput.cursorPosition
                    scratchpadInput.selectionEnd = scratchpadInput.cursorPosition
                })
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                scratchpadContents = ""
                scratchpadFile.setText(scratchpadContents)
                if (scratchpadInput)
                    scratchpadInput.text = scratchpadContents
                if (pendingReload && GlobalStates.scratchpadOpen) {
                    pendingReload = false
                    Qt.callLater(() => {
                        scratchpadInput.forceActiveFocus()
                        scratchpadInput.cursorPosition = scratchpadInput.text.length
                        scratchpadInput.selectionStart = scratchpadInput.cursorPosition
                        scratchpadInput.selectionEnd = scratchpadInput.cursorPosition
                    })
                }
            } else {
                console.log("[Scratchpad] Error loading file: " + error)
            }
        }
    }

    IpcHandler {
        target: "scratchpad"

        function toggle(): void {
            GlobalStates.scratchpadOpen = !GlobalStates.scratchpadOpen
        }

        function open(): void {
            GlobalStates.scratchpadOpen = true
        }

        function close(): void {
            GlobalStates.scratchpadOpen = false
        }
    }

    GlobalShortcut {
        name: "scratchpadToggle"
        description: "Toggles dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = !GlobalStates.scratchpadOpen
    }

    GlobalShortcut {
        name: "scratchpadOpen"
        description: "Opens dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = true
    }

    GlobalShortcut {
        name: "scratchpadClose"
        description: "Closes dropdown scratchpad"
        onPressed: GlobalStates.scratchpadOpen = false
    }
}

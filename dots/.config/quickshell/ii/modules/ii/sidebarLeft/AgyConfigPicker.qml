pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Rectangle {
    id: root
    signal closeRequested()

    property var items: []
    readonly property string scriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/agy-config.py`)

    function refresh() {
        getProc.running = false;
        getProc.running = true;
    }

    function toggleOrCycle(item) {
        let nextVal = item.value;
        if (item.kind === "bool") {
            nextVal = !item.value;
        } else if (item.kind === "enum" && item.options?.length > 0) {
            const idx = item.options.indexOf(item.value);
            nextVal = item.options[(idx + 1) % item.options.length];
        } else {
            return;
        }
        setProc.running = false;
        setProc.command = ["python3", root.scriptPath, "set", item.key, JSON.stringify(nextVal)];
        setProc.running = true;
    }

    onVisibleChanged: {
        if (visible)
            root.refresh();
    }

    Process {
        id: getProc
        command: ["python3", root.scriptPath, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    if (Array.isArray(parsed))
                        root.items = parsed;
                } catch (e) {}
            }
        }
    }

    Process {
        id: setProc
        onExited: root.refresh()
    }

    implicitHeight: Math.min(320, cfgCol.implicitHeight + 16)
    clip: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    ColumnLayout {
        id: cfgCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 2

            MaterialSymbol {
                text: "tune"
                iconSize: 16
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colSubtext
                text: "Antigravity Config"
            }
            RippleButton {
                implicitWidth: 26
                implicitHeight: 26
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                onClicked: root.refresh()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ListView {
            id: cfgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.min(255, contentHeight)
            clip: true
            spacing: 2
            model: root.items

            delegate: RippleButton {
                id: cfgRow
                required property var modelData
                readonly property bool editable: modelData.kind === "bool" || modelData.kind === "enum"
                width: cfgList.width
                implicitHeight: 30
                buttonRadius: Appearance.rounding.small
                colBackground: "transparent"
                colBackgroundHover: editable ? Appearance.colors.colSurfaceContainerHigh : "transparent"
                onClicked: if (editable) root.toggleOrCycle(modelData)

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.monospace
                        color: Appearance.m3colors.m3onSurface
                        elide: Text.ElideRight
                        text: modelData.key
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.monospace
                        font.weight: cfgRow.editable ? Font.Medium : Font.Normal
                        color: modelData.kind === "bool"
                            ? (modelData.value ? Appearance.colors.colPrimary : Appearance.colors.colSubtext)
                            : (cfgRow.editable ? Appearance.colors.colPrimary : Appearance.colors.colSubtext)
                        text: String(modelData.value)
                    }
                }
            }
        }
    }
}
